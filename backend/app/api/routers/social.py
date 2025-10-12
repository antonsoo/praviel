"""Social features API endpoints for friends and leaderboards."""

from datetime import datetime, timedelta, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.db.social_models import (
    FriendChallenge,
    Friendship,
    PowerUpInventory,
    PowerUpUsage,
)
from app.db.user_models import User, UserProfile, UserProgress
from app.security.auth import get_current_user

router = APIRouter(prefix="/social", tags=["Social"])

# ---------------------------------------------------------------------
# Pydantic Models
# ---------------------------------------------------------------------


class LeaderboardUserResponse(BaseModel):
    """Leaderboard entry for a single user."""

    rank: int
    user_id: int
    username: str
    xp: int
    level: int
    is_current_user: bool = False
    avatar_url: Optional[str] = None


class LeaderboardResponse(BaseModel):
    """Leaderboard rankings."""

    board_type: str
    users: List[LeaderboardUserResponse]
    current_user_rank: int
    total_users: int


class FriendRequest(BaseModel):
    """Request to add a friend."""

    friend_username: str = Field(..., description="Username of the friend to add")


class FriendResponse(BaseModel):
    """Friend information."""

    user_id: int
    username: str
    xp: int
    level: int
    status: str  # pending, accepted, blocked
    is_online: bool = False


class ChallengeRequest(BaseModel):
    """Request to create a friend challenge."""

    friend_id: int
    challenge_type: str = Field(..., description="Type: xp_race, lesson_count, streak")
    target_value: int = Field(..., gt=0, description="Target to reach")
    duration_hours: int = Field(default=24, ge=1, le=168, description="Challenge duration in hours")


class ChallengeResponse(BaseModel):
    """Challenge information."""

    id: int
    challenge_type: str
    target_value: int
    initiator_username: str
    opponent_username: str
    initiator_progress: int
    opponent_progress: int
    status: str
    starts_at: datetime
    expires_at: datetime


class PowerUpPurchaseRequest(BaseModel):
    """Request to purchase a power-up."""

    power_up_type: str = Field(..., description="Type: streak_freeze, xp_boost, hint_reveal")
    quantity: int = Field(default=1, ge=1, le=10)


class PowerUpInventoryResponse(BaseModel):
    """Power-up inventory."""

    power_up_type: str
    quantity: int
    active_count: int


# ---------------------------------------------------------------------
# Leaderboard Endpoints
# ---------------------------------------------------------------------


@router.get("/leaderboard/{board_type}", response_model=LeaderboardResponse)
async def get_leaderboard(
    board_type: str,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get leaderboard rankings.

    Board types:
    - global: All users worldwide
    - friends: Only user's friends
    - local: Users in the same region (based on user profile)
    """
    if board_type not in ["global", "friends", "local"]:
        raise HTTPException(status_code=400, detail="Invalid board type")

    # For friends board, first get friend IDs
    friend_ids = []
    if board_type == "friends":
        friend_query = select(Friendship.friend_id).where(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.status == "accepted",
            )
        )
        result = await db.execute(friend_query)
        friend_ids = [row[0] for row in result.fetchall()]
        friend_ids.append(current_user.id)  # Include current user

    # Determine effective board type (local falls back to global if no region)
    user_region: Optional[str] = None
    effective_board_type = board_type
    if board_type == "local":
        region_result = await db.execute(
            select(UserProfile.region).where(UserProfile.user_id == current_user.id)
        )
        user_region = region_result.scalar()
        if user_region:
            user_region = user_region.strip()
        if not user_region:
            effective_board_type = "global"
        else:
            effective_board_type = "local"

    # Build query
    if effective_board_type == "global":
        # Get top users by XP
        query = (
            select(
                UserProgress.user_id,
                UserProgress.xp_total,
                UserProgress.level,
                User.username,
            )
            .join(User, User.id == UserProgress.user_id)
            .where(User.is_active == True)  # noqa: E712
            .order_by(desc(UserProgress.xp_total))
            .limit(limit)
        )
    elif effective_board_type == "friends":
        if not friend_ids:
            # No friends yet
            return LeaderboardResponse(
                board_type=board_type,
                users=[],
                current_user_rank=1,
                total_users=0,
            )

        query = (
            select(
                UserProgress.user_id,
                UserProgress.xp_total,
                UserProgress.level,
                User.username,
            )
            .join(User, User.id == UserProgress.user_id)
            .where(
                and_(
                    UserProgress.user_id.in_(friend_ids),
                    User.is_active == True,  # noqa: E712
                )
            )
            .order_by(desc(UserProgress.xp_total))
            .limit(limit)
        )
    else:
        # Local leaderboard filtered by matching region
        query = (
            select(
                UserProgress.user_id,
                UserProgress.xp_total,
                UserProgress.level,
                User.username,
            )
            .join(User, User.id == UserProgress.user_id)
            .join(UserProfile, UserProfile.user_id == User.id)
            .where(
                and_(
                    User.is_active == True,  # noqa: E712
                    UserProfile.region == user_region,
                )
            )
            .order_by(desc(UserProgress.xp_total))
            .limit(limit)
        )

    result = await db.execute(query)
    rows = result.fetchall()

    # Convert to response format
    users = []
    current_user_rank = None
    for rank, row in enumerate(rows, start=1):
        user_id, xp, level, username = row
        is_current = user_id == current_user.id
        if is_current:
            current_user_rank = rank

        users.append(
            LeaderboardUserResponse(
                rank=rank,
                user_id=user_id,
                username=username,
                xp=xp,
                level=level,
                is_current_user=is_current,
            )
        )

    # If current user not in top N, find their rank
    if current_user_rank is None:
        if effective_board_type == "global":
            count_query = select(func.count()).select_from(
                select(UserProgress.user_id)
                .join(User)
                .where(
                    and_(
                        User.is_active == True,  # noqa: E712
                        UserProgress.xp_total
                        > (select(UserProgress.xp_total).where(UserProgress.user_id == current_user.id)),
                    )
                )
                .subquery()
            )
        elif effective_board_type == "friends":
            count_query = select(func.count()).select_from(
                select(UserProgress.user_id)
                .where(
                    and_(
                        UserProgress.user_id.in_(friend_ids),
                        UserProgress.xp_total
                        > (select(UserProgress.xp_total).where(UserProgress.user_id == current_user.id)),
                    )
                )
                .subquery()
            )
        else:
            count_query = select(func.count()).select_from(
                select(UserProgress.user_id)
                .join(User, User.id == UserProgress.user_id)
                .join(UserProfile, UserProfile.user_id == User.id)
                .where(
                    and_(
                        User.is_active == True,  # noqa: E712
                        UserProfile.region == user_region,
                        UserProgress.xp_total
                        > (select(UserProgress.xp_total).where(UserProgress.user_id == current_user.id)),
                    )
                )
                .subquery()
            )

        count_result = await db.execute(count_query)
        count = count_result.scalar() or 0
        current_user_rank = count + 1

    # Total users count
    if effective_board_type == "global":
        total_query = select(func.count(UserProgress.user_id)).join(User).where(User.is_active == True)  # noqa: E712
    elif effective_board_type == "friends":
        total_query = select(func.count(UserProgress.user_id)).where(UserProgress.user_id.in_(friend_ids))
    else:
        total_query = (
            select(func.count(UserProgress.user_id))
            .join(User, User.id == UserProgress.user_id)
            .join(UserProfile, UserProfile.user_id == User.id)
            .where(
                and_(
                    User.is_active == True,  # noqa: E712
                    UserProfile.region == user_region,
                )
            )
        )

    total_result = await db.execute(total_query)
    total_users = total_result.scalar() or 0

    return LeaderboardResponse(
        board_type=board_type,
        users=users,
        current_user_rank=current_user_rank,
        total_users=total_users,
    )


@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_default_leaderboard(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get global leaderboard (convenience endpoint, same as /leaderboard/global)."""
    return await get_leaderboard("global", limit, current_user, db)


# ---------------------------------------------------------------------
# Friend Management
# ---------------------------------------------------------------------


@router.get("/friends", response_model=List[FriendResponse])
async def get_friends(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's friends list."""
    query = (
        select(
            Friendship.friend_id,
            Friendship.status,
            User.username,
            UserProgress.xp_total,
            UserProgress.level,
        )
        .join(User, User.id == Friendship.friend_id)
        .outerjoin(UserProgress, UserProgress.user_id == Friendship.friend_id)
        .where(Friendship.user_id == current_user.id)
        .order_by(desc(UserProgress.xp_total))
    )

    result = await db.execute(query)
    rows = result.fetchall()

    friends = []
    for row in rows:
        friend_id, status, username, xp, level = row
        friends.append(
            FriendResponse(
                user_id=friend_id,
                username=username,
                xp=xp or 0,  # Default to 0 if user has no progress yet
                level=level or 0,  # Default to 0 if user has no progress yet
                status=status,
                is_online=False,  # TODO: Implement online status
            )
        )

    return friends


@router.post("/friends/add", response_model=dict)
async def add_friend(
    request: FriendRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a friend request."""
    # Find friend by username
    friend_query = select(User).where(User.username == request.friend_username)
    friend_result = await db.execute(friend_query)
    friend = friend_result.scalar_one_or_none()

    if not friend:
        raise HTTPException(status_code=404, detail="User not found")

    if friend.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot add yourself as a friend")

    # Check if friendship already exists
    existing_query = select(Friendship).where(
        and_(
            Friendship.user_id == current_user.id,
            Friendship.friend_id == friend.id,
        )
    )
    existing_result = await db.execute(existing_query)
    existing = existing_result.scalar_one_or_none()

    if existing:
        raise HTTPException(status_code=400, detail="Friend request already sent")

    # Create bidirectional friendship records
    friendship1 = Friendship(
        user_id=current_user.id,
        friend_id=friend.id,
        status="pending",
        initiated_by_user_id=current_user.id,
    )
    friendship2 = Friendship(
        user_id=friend.id,
        friend_id=current_user.id,
        status="pending",
        initiated_by_user_id=current_user.id,
    )

    db.add(friendship1)
    db.add(friendship2)
    await db.commit()

    return {"message": f"Friend request sent to {friend.username}"}


@router.post("/friends/{friend_id}/accept", response_model=dict)
async def accept_friend_request(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Accept a friend request."""
    # Find the friendship records (both directions)
    query1 = select(Friendship).where(
        and_(
            Friendship.user_id == current_user.id,
            Friendship.friend_id == friend_id,
            Friendship.status == "pending",
        )
    )
    query2 = select(Friendship).where(
        and_(
            Friendship.user_id == friend_id,
            Friendship.friend_id == current_user.id,
            Friendship.status == "pending",
        )
    )

    result1 = await db.execute(query1)
    friendship1 = result1.scalar_one_or_none()

    result2 = await db.execute(query2)
    friendship2 = result2.scalar_one_or_none()

    if not friendship1 or not friendship2:
        raise HTTPException(status_code=404, detail="Friend request not found")

    # Update both to accepted
    now = datetime.now(timezone.utc)
    friendship1.status = "accepted"
    friendship1.accepted_at = now
    friendship2.status = "accepted"
    friendship2.accepted_at = now

    await db.commit()

    return {"message": "Friend request accepted"}


@router.delete("/friends/{friend_id}", response_model=dict)
async def remove_friend(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove a friend."""
    # Delete both friendship records
    query = select(Friendship).where(
        or_(
            and_(Friendship.user_id == current_user.id, Friendship.friend_id == friend_id),
            and_(Friendship.user_id == friend_id, Friendship.friend_id == current_user.id),
        )
    )

    result = await db.execute(query)
    friendships = result.scalars().all()

    if not friendships:
        raise HTTPException(status_code=404, detail="Friendship not found")

    for friendship in friendships:
        await db.delete(friendship)

    await db.commit()

    return {"message": "Friend removed"}


# ---------------------------------------------------------------------
# Friend Challenges
# ---------------------------------------------------------------------


@router.post("/challenges/create", response_model=ChallengeResponse)
async def create_challenge(
    request: ChallengeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a friend challenge."""
    # Verify friendship exists
    friendship_query = select(Friendship).where(
        and_(
            Friendship.user_id == current_user.id,
            Friendship.friend_id == request.friend_id,
            Friendship.status == "accepted",
        )
    )
    friendship_result = await db.execute(friendship_query)
    friendship = friendship_result.scalar_one_or_none()

    if not friendship:
        raise HTTPException(status_code=400, detail="Not friends with this user")

    # Create challenge
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(hours=request.duration_hours)

    challenge = FriendChallenge(
        initiator_user_id=current_user.id,
        opponent_user_id=request.friend_id,
        challenge_type=request.challenge_type,
        target_value=request.target_value,
        status="pending",
        starts_at=now,
        expires_at=expires_at,
    )

    db.add(challenge)
    await db.commit()
    await db.refresh(challenge)

    # Get usernames
    user_query = select(User.username).where(User.id.in_([current_user.id, request.friend_id]))
    user_result = await db.execute(user_query)
    usernames = {row[0] for row in user_result.fetchall()}

    return ChallengeResponse(
        id=challenge.id,
        challenge_type=challenge.challenge_type,
        target_value=challenge.target_value,
        initiator_username=current_user.username,
        opponent_username=list(usernames - {current_user.username})[0] if usernames else "Unknown",
        initiator_progress=challenge.initiator_progress,
        opponent_progress=challenge.opponent_progress,
        status=challenge.status,
        starts_at=challenge.starts_at,
        expires_at=challenge.expires_at,
    )


@router.get("/challenges", response_model=List[ChallengeResponse])
async def get_challenges(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's active challenges."""
    query = select(FriendChallenge).where(
        and_(
            or_(
                FriendChallenge.initiator_user_id == current_user.id,
                FriendChallenge.opponent_user_id == current_user.id,
            ),
            FriendChallenge.status.in_(["pending", "active"]),
        )
    )

    result = await db.execute(query)
    challenges = result.scalars().all()

    # Get all involved user IDs
    user_ids = set()
    for c in challenges:
        user_ids.add(c.initiator_user_id)
        user_ids.add(c.opponent_user_id)

    # Fetch usernames (guard against empty set to avoid SQL error)
    if not user_ids:
        return []

    user_query = select(User.id, User.username).where(User.id.in_(user_ids))
    user_result = await db.execute(user_query)
    username_map = {row[0]: row[1] for row in user_result.fetchall()}

    # Convert to response
    responses = []
    for c in challenges:
        responses.append(
            ChallengeResponse(
                id=c.id,
                challenge_type=c.challenge_type,
                target_value=c.target_value,
                initiator_username=username_map.get(c.initiator_user_id, "Unknown"),
                opponent_username=username_map.get(c.opponent_user_id, "Unknown"),
                initiator_progress=c.initiator_progress,
                opponent_progress=c.opponent_progress,
                status=c.status,
                starts_at=c.starts_at,
                expires_at=c.expires_at,
            )
        )

    return responses


# ---------------------------------------------------------------------
# Power-Ups
# ---------------------------------------------------------------------


@router.get("/power-ups", response_model=List[PowerUpInventoryResponse])
async def get_power_ups(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's power-up inventory."""
    query = select(PowerUpInventory).where(PowerUpInventory.user_id == current_user.id)

    result = await db.execute(query)
    inventory = result.scalars().all()

    return [
        PowerUpInventoryResponse(
            power_up_type=item.power_up_type,
            quantity=item.quantity,
            active_count=item.active_count,
        )
        for item in inventory
    ]


@router.post("/power-ups/purchase", response_model=dict)
async def purchase_power_up(
    request: PowerUpPurchaseRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Purchase a power-up with coins/XP.

    Costs:
    - streak_freeze: 100 XP
    - xp_boost: 200 XP
    - hint_reveal: 50 XP
    """
    costs = {
        "streak_freeze": 100,
        "xp_boost": 200,
        "hint_reveal": 50,
    }

    if request.power_up_type not in costs:
        raise HTTPException(status_code=400, detail="Invalid power-up type")

    total_cost = costs[request.power_up_type] * request.quantity

    # Check user's XP
    progress_query = select(UserProgress).where(UserProgress.user_id == current_user.id)
    progress_result = await db.execute(progress_query)
    progress = progress_result.scalar_one_or_none()

    if not progress or progress.xp_total < total_cost:
        raise HTTPException(status_code=400, detail="Insufficient XP")

    # Deduct XP
    progress.xp_total -= total_cost

    # Add to inventory
    inventory_query = select(PowerUpInventory).where(
        and_(
            PowerUpInventory.user_id == current_user.id,
            PowerUpInventory.power_up_type == request.power_up_type,
        )
    )
    inventory_result = await db.execute(inventory_query)
    inventory = inventory_result.scalar_one_or_none()

    if inventory:
        inventory.quantity += request.quantity
    else:
        inventory = PowerUpInventory(
            user_id=current_user.id,
            power_up_type=request.power_up_type,
            quantity=request.quantity,
        )
        db.add(inventory)

    await db.commit()

    return {
        "message": f"Purchased {request.quantity}x {request.power_up_type}",
        "remaining_xp": progress.xp_total,
        "new_quantity": inventory.quantity,
    }


@router.post("/power-ups/{power_up_type}/activate", response_model=dict)
async def activate_power_up(
    power_up_type: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Activate a power-up from inventory."""
    # Check inventory
    inventory_query = select(PowerUpInventory).where(
        and_(
            PowerUpInventory.user_id == current_user.id,
            PowerUpInventory.power_up_type == power_up_type,
        )
    )
    inventory_result = await db.execute(inventory_query)
    inventory = inventory_result.scalar_one_or_none()

    if not inventory or inventory.quantity < 1:
        raise HTTPException(status_code=400, detail="No power-ups available")

    # Deduct from inventory
    inventory.quantity -= 1
    inventory.active_count += 1

    # Create usage record
    duration_map = {
        "streak_freeze": 24,  # 24 hours
        "xp_boost": 1,  # 1 hour
        "hint_reveal": 0,  # Instant use
    }

    now = datetime.now(timezone.utc)
    expires_at = (
        now + timedelta(hours=duration_map.get(power_up_type, 0)) if duration_map.get(power_up_type) else None
    )

    usage = PowerUpUsage(
        user_id=current_user.id,
        power_up_type=power_up_type,
        activated_at=now,
        expires_at=expires_at,
        is_active=True,
    )

    db.add(usage)
    await db.commit()

    return {
        "message": f"Activated {power_up_type}",
        "expires_at": expires_at.isoformat() if expires_at else None,
    }
