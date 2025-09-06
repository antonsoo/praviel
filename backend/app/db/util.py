from __future__ import annotations
from sqlalchemy import text, bindparam
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql.elements import TextClause

def text_with_json(sql: str, *json_param_names: str) -> TextClause:
    """
    Build a SQLAlchemy text() statement where selected named parameters
    are bound as PostgreSQL JSONB to avoid asyncpg 'dict has no encode' errors.
    """
    stmt = text(sql)
    for name in json_param_names:
        stmt = stmt.bindparams(bindparam(name, type_=JSONB))
    return stmt
