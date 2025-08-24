from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
# Import the modules we just created using the aggregated imports
from app import crud, schemas

router = APIRouter()

@router.get("/", response_model=List[schemas.Script])
async def read_scripts(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
):
    """Retrieve scripts."""
    scripts = await crud.script.get_multi(db, skip=skip, limit=limit)
    return scripts

@router.post("/", response_model=schemas.Script, status_code=status.HTTP_201_CREATED)
async def create_script(
    *,
    db: AsyncSession = Depends(get_db),
    script_in: schemas.ScriptCreate,
):
    """Create new script."""
    # Database UNIQUE constraints will prevent duplicate names/codes.
    script = await crud.script.create(db=db, obj_in=script_in)
    return script

@router.get("/{script_id}", response_model=schemas.Script)
async def read_script_by_id(
    script_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific script by ID."""
    script = await crud.script.get(db=db, id=script_id)
    if not script:
        raise HTTPException(status_code=404, detail="Script not found")
    return script

@router.put("/{script_id}", response_model=schemas.Script)
async def update_script(
    *,
    db: AsyncSession = Depends(get_db),
    script_id: int,
    script_in: schemas.ScriptUpdate,
):
    """Update a script."""
    script = await crud.script.get(db=db, id=script_id)
    if not script:
        raise HTTPException(status_code=404, detail="Script not found")
    script = await crud.script.update(db=db, db_obj=script, obj_in=script_in)
    return script

@router.delete("/{script_id}", response_model=schemas.Script)
async def delete_script(
    *,
    db: AsyncSession = Depends(get_db),
    script_id: int,
):
    """Delete a script."""
    script = await crud.script.get(db=db, id=script_id)
    if not script:
        raise HTTPException(status_code=404, detail="Script not found")
    # Note: Deletion will fail if the script is still associated with any languages (Foreign Key constraint).
    script = await crud.script.remove(db=db, id=script_id)
    return script