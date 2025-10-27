"""Email marketing service for Resend Broadcasts and Audiences.

This module provides functionality for:
- Managing audiences (mailing lists)
- Managing contacts within audiences
- Sending broadcast emails to audiences
- Handling unsubscribe management

Requires EMAIL_PROVIDER=resend and RESEND_API_KEY to be configured.
"""

from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass
from enum import Enum
from typing import Any

logger = logging.getLogger(__name__)


class AudiencePermission(str, Enum):
    """Permission level for audience members."""

    SUBSCRIBED = "subscribed"
    UNSUBSCRIBED = "unsubscribed"


@dataclass
class Audience:
    """Represents a Resend audience (mailing list)."""

    id: str
    name: str
    created_at: str | None = None


@dataclass
class Contact:
    """Represents a contact in an audience."""

    id: str
    email: str
    first_name: str | None = None
    last_name: str | None = None
    unsubscribed: bool = False
    created_at: str | None = None


@dataclass
class BroadcastCreateParams:
    """Parameters for creating a broadcast email."""

    audience_id: str
    from_email: str  # e.g., "PRAVIEL <marketing@praviel.com>"
    subject: str
    html: str | None = None
    text: str | None = None
    name: str | None = None  # Internal name for the broadcast
    topic_id: str | None = None  # Topic grouping


@dataclass
class Broadcast:
    """Represents a created broadcast."""

    id: str
    audience_id: str | None = None
    name: str | None = None
    status: str | None = None
    created_at: str | None = None


class EmailMarketingServiceError(RuntimeError):
    """Raised when email marketing operations fail."""

    pass


class EmailMarketingService:
    """Service for managing email marketing via Resend Broadcasts and Audiences.

    This service provides methods to:
    - Create and manage audiences
    - Add and remove contacts from audiences
    - Create and send broadcast emails
    - Handle unsubscribes automatically

    Example:
        service = EmailMarketingService(api_key="re_your_key")

        # Create an audience
        audience = await service.create_audience("Newsletter Subscribers")

        # Add contacts
        contact = await service.add_contact(
            audience_id=audience.id,
            email="user@example.com",
            first_name="John",
            last_name="Doe"
        )

        # Send broadcast
        broadcast = await service.create_broadcast(
            BroadcastCreateParams(
                audience_id=audience.id,
                from_email="PRAVIEL <noreply@praviel.com>",
                subject="Welcome to PRAVIEL",
                html=(
                    "<p>Hi {{{FIRST_NAME|there}}}, welcome!</p>"
                    "<p><a href='{{{RESEND_UNSUBSCRIBE_URL}}}'>Unsubscribe</a></p>"
                ),
            )
        )
        await service.send_broadcast(broadcast.id)
    """

    def __init__(self, api_key: str):
        """Initialize email marketing service.

        Args:
            api_key: Resend API key (starts with 're_')
        """
        if not api_key or not api_key.startswith("re_"):
            raise ValueError("Valid Resend API key is required")

        self.api_key = api_key

        try:
            import resend
        except ImportError as exc:
            msg = "Resend library not installed. Run: pip install resend"
            raise ImportError(msg) from exc

        resend.api_key = api_key
        self.resend = resend

    @staticmethod
    async def _run_in_thread(func: Any, *args: Any, **kwargs: Any) -> Any:
        """Run blocking Resend SDK calls without freezing the event loop."""
        return await asyncio.to_thread(func, *args, **kwargs)

    # -------------------------------------------------------------------------
    # Audience Management
    # -------------------------------------------------------------------------

    async def create_audience(self, name: str) -> Audience:
        """Create a new audience (mailing list).

        Args:
            name: Name of the audience (e.g., "Newsletter Subscribers")

        Returns:
            Created Audience object with ID

        Example:
            audience = await service.create_audience("Product Updates")
        """

        def _create() -> dict[str, Any]:
            return self.resend.audiences.create({"name": name})

        try:
            result = await self._run_in_thread(_create)
            return Audience(
                id=result.get("id", ""),
                name=result.get("name", name),
                created_at=result.get("created_at"),
            )
        except Exception as exc:
            msg = f"Failed to create audience '{name}': {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def list_audiences(self) -> list[Audience]:
        """List all audiences.

        Returns:
            List of Audience objects

        Example:
            audiences = await service.list_audiences()
            for aud in audiences:
                print(f"{aud.name}: {aud.id}")
        """

        def _list() -> dict[str, Any]:
            return self.resend.audiences.list()

        try:
            result = await self._run_in_thread(_list)
            data = result.get("data", [])
            return [
                Audience(id=item.get("id", ""), name=item.get("name", ""), created_at=item.get("created_at"))
                for item in data
            ]
        except Exception as exc:
            msg = f"Failed to list audiences: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def get_audience(self, audience_id: str) -> Audience:
        """Get details of a specific audience.

        Args:
            audience_id: The audience ID

        Returns:
            Audience object

        Example:
            audience = await service.get_audience("78261eea-...")
        """

        def _get() -> dict[str, Any]:
            return self.resend.audiences.get(audience_id)

        try:
            result = await self._run_in_thread(_get)
            return Audience(
                id=result.get("id", ""), name=result.get("name", ""), created_at=result.get("created_at")
            )
        except Exception as exc:
            msg = f"Failed to get audience {audience_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def delete_audience(self, audience_id: str) -> bool:
        """Delete an audience and all its contacts.

        Args:
            audience_id: The audience ID to delete

        Returns:
            True if successful

        Example:
            await service.delete_audience("78261eea-...")
        """

        def _delete() -> dict[str, Any]:
            return self.resend.audiences.remove(audience_id)

        try:
            await self._run_in_thread(_delete)
            logger.info(f"Deleted audience {audience_id}")
            return True
        except Exception as exc:
            msg = f"Failed to delete audience {audience_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    # -------------------------------------------------------------------------
    # Contact Management
    # -------------------------------------------------------------------------

    async def add_contact(
        self,
        audience_id: str,
        email: str,
        first_name: str | None = None,
        last_name: str | None = None,
        unsubscribed: bool = False,
    ) -> Contact:
        """Add a contact to an audience.

        Args:
            audience_id: The audience ID
            email: Contact's email address
            first_name: Contact's first name (optional)
            last_name: Contact's last name (optional)
            unsubscribed: Whether the contact is unsubscribed (default: False)

        Returns:
            Created Contact object

        Example:
            contact = await service.add_contact(
                audience_id="78261eea-...",
                email="user@example.com",
                first_name="Jane",
                last_name="Doe"
            )
        """

        def _add() -> dict[str, Any]:
            params: dict[str, Any] = {
                "email": email,
                "unsubscribed": unsubscribed,
            }
            if first_name:
                params["first_name"] = first_name
            if last_name:
                params["last_name"] = last_name

            return self.resend.contacts.create(audience_id=audience_id, params=params)

        try:
            result = await self._run_in_thread(_add)
            return Contact(
                id=result.get("id", ""),
                email=email,
                first_name=first_name,
                last_name=last_name,
                unsubscribed=unsubscribed,
                created_at=result.get("created_at"),
            )
        except Exception as exc:
            msg = f"Failed to add contact {email} to audience {audience_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def update_contact(
        self,
        audience_id: str,
        contact_id: str,
        email: str | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        unsubscribed: bool | None = None,
    ) -> Contact:
        """Update a contact's information.

        Args:
            audience_id: The audience ID
            contact_id: The contact ID to update
            email: New email address (optional)
            first_name: New first name (optional)
            last_name: New last name (optional)
            unsubscribed: New subscription status (optional)

        Returns:
            Updated Contact object

        Example:
            contact = await service.update_contact(
                audience_id="78261eea-...",
                contact_id="479e3145-...",
                first_name="John",
                unsubscribed=True
            )
        """

        def _update() -> dict[str, Any]:
            params: dict[str, Any] = {}
            if email is not None:
                params["email"] = email
            if first_name is not None:
                params["first_name"] = first_name
            if last_name is not None:
                params["last_name"] = last_name
            if unsubscribed is not None:
                params["unsubscribed"] = unsubscribed

            return self.resend.contacts.update(audience_id=audience_id, id=contact_id, params=params)

        try:
            result = await self._run_in_thread(_update)
            return Contact(
                id=result.get("id", contact_id),
                email=result.get("email", email or ""),
                first_name=result.get("first_name"),
                last_name=result.get("last_name"),
                unsubscribed=result.get("unsubscribed", False),
                created_at=result.get("created_at"),
            )
        except Exception as exc:
            msg = f"Failed to update contact {contact_id} in audience {audience_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def remove_contact(self, audience_id: str, contact_id: str) -> bool:
        """Remove a contact from an audience.

        Args:
            audience_id: The audience ID
            contact_id: The contact ID to remove

        Returns:
            True if successful

        Example:
            await service.remove_contact("78261eea-...", "479e3145-...")
        """

        def _remove() -> dict[str, Any]:
            return self.resend.contacts.remove(audience_id=audience_id, id=contact_id)

        try:
            await self._run_in_thread(_remove)
            logger.info(f"Removed contact {contact_id} from audience {audience_id}")
            return True
        except Exception as exc:
            msg = f"Failed to remove contact {contact_id} from audience {audience_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def list_contacts(self, audience_id: str) -> list[Contact]:
        """List all contacts in an audience.

        Args:
            audience_id: The audience ID

        Returns:
            List of Contact objects

        Example:
            contacts = await service.list_contacts("78261eea-...")
            for contact in contacts:
                print(f"{contact.email}: {contact.first_name}")
        """

        def _list() -> dict[str, Any]:
            return self.resend.contacts.list(audience_id=audience_id)

        try:
            result = await self._run_in_thread(_list)
            data = result.get("data", [])
            return [
                Contact(
                    id=item.get("id", ""),
                    email=item.get("email", ""),
                    first_name=item.get("first_name"),
                    last_name=item.get("last_name"),
                    unsubscribed=item.get("unsubscribed", False),
                    created_at=item.get("created_at"),
                )
                for item in data
            ]
        except Exception as exc:
            msg = f"Failed to list contacts for audience {audience_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    # -------------------------------------------------------------------------
    # Broadcast Management
    # -------------------------------------------------------------------------

    async def create_broadcast(self, params: BroadcastCreateParams) -> Broadcast:
        """Create a broadcast email to send to an audience.

        The HTML/text content should include:
        - {{{FIRST_NAME|fallback}}} for personalization
        - {{{LAST_NAME|fallback}}} for personalization
        - {{{RESEND_UNSUBSCRIBE_URL}}} for one-click unsubscribe (REQUIRED for marketing emails)

        Args:
            params: Broadcast creation parameters

        Returns:
            Created Broadcast object

        Example:
            broadcast = await service.create_broadcast(
                BroadcastCreateParams(
                    audience_id="78261eea-...",
                    from_email="PRAVIEL <marketing@praviel.com>",
                    subject="New Features Released!",
                    html='''
                        <h1>Hi {{{FIRST_NAME|there}}}!</h1>
                        <p>Check out our new features...</p>
                        <p><a href="{{{RESEND_UNSUBSCRIBE_URL}}}">Unsubscribe</a></p>
                    ''',
                    name="Feature Announcement - Oct 2025"
                )
            )
        """

        def _create() -> dict[str, Any]:
            broadcast_params: dict[str, Any] = {
                "audience_id": params.audience_id,
                "from": params.from_email,
                "subject": params.subject,
            }

            if params.html:
                broadcast_params["html"] = params.html
            if params.text:
                broadcast_params["text"] = params.text
            if params.name:
                broadcast_params["name"] = params.name
            if params.topic_id:
                broadcast_params["topic_id"] = params.topic_id

            return self.resend.broadcasts.create(broadcast_params)

        try:
            result = await self._run_in_thread(_create)
            logger.info(f"Created broadcast {result.get('id')} for audience {params.audience_id}")
            return Broadcast(
                id=result.get("id", ""),
                audience_id=params.audience_id,
                name=params.name,
                status=result.get("status"),
                created_at=result.get("created_at"),
            )
        except Exception as exc:
            msg = f"Failed to create broadcast: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def send_broadcast(self, broadcast_id: str) -> bool:
        """Send a created broadcast immediately.

        Args:
            broadcast_id: The broadcast ID to send

        Returns:
            True if successful

        Example:
            await service.send_broadcast("49a3999c-...")
        """

        def _send() -> dict[str, Any]:
            return self.resend.broadcasts.send(broadcast_id)

        try:
            await self._run_in_thread(_send)
            logger.info(f"Sent broadcast {broadcast_id}")
            return True
        except Exception as exc:
            msg = f"Failed to send broadcast {broadcast_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc

    async def get_broadcast(self, broadcast_id: str) -> Broadcast:
        """Get details of a specific broadcast.

        Args:
            broadcast_id: The broadcast ID

        Returns:
            Broadcast object

        Example:
            broadcast = await service.get_broadcast("49a3999c-...")
        """

        def _get() -> dict[str, Any]:
            return self.resend.broadcasts.get(broadcast_id)

        try:
            result = await self._run_in_thread(_get)
            return Broadcast(
                id=result.get("id", ""),
                audience_id=result.get("audience_id"),
                name=result.get("name"),
                status=result.get("status"),
                created_at=result.get("created_at"),
            )
        except Exception as exc:
            msg = f"Failed to get broadcast {broadcast_id}: {exc}"
            logger.error(msg)
            raise EmailMarketingServiceError(msg) from exc


# Factory function for easy initialization
def create_email_marketing_service(api_key: str) -> EmailMarketingService:
    """Create email marketing service.

    Args:
        api_key: Resend API key

    Returns:
        Configured EmailMarketingService instance

    Example:
        service = create_email_marketing_service("re_your_key_here")
    """
    return EmailMarketingService(api_key=api_key)


__all__ = [
    "EmailMarketingService",
    "EmailMarketingServiceError",
    "Audience",
    "Contact",
    "Broadcast",
    "BroadcastCreateParams",
    "AudiencePermission",
    "create_email_marketing_service",
]
