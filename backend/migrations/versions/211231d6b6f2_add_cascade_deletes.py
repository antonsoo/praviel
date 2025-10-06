"""add_cascade_deletes

Revision ID: 211231d6b6f2
Revises: d3a30a71ca06
Create Date: 2025-10-06 11:11:54.073489

"""

from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "211231d6b6f2"
down_revision: Union[str, Sequence[str], None] = "d3a30a71ca06"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add CASCADE/RESTRICT behaviors to foreign key constraints that need them.

    Based on actual database inspection:
    - User tables ALREADY have CASCADE (added by auth migration) - skip them
    - Text tables need CASCADE/RESTRICT added
    - Also add text_work -> language RESTRICT
    """
    # Text hierarchy: TextWork -> TextSegment should CASCADE
    # When deleting a work, delete all its segments
    op.drop_constraint("text_segment_work_id_fkey", "text_segment", type_="foreignkey")
    op.create_foreign_key(
        "text_segment_work_id_fkey", "text_segment", "text_work", ["work_id"], ["id"], ondelete="CASCADE"
    )

    # SourceDoc -> TextWork should be RESTRICT (don't allow deleting source if works exist)
    op.drop_constraint("text_work_source_id_fkey", "text_work", type_="foreignkey")
    op.create_foreign_key(
        "text_work_source_id_fkey", "text_work", "source_doc", ["source_id"], ["id"], ondelete="RESTRICT"
    )

    # Language -> TextWork should be RESTRICT (don't allow deleting language if works exist)
    op.drop_constraint("text_work_language_id_fkey", "text_work", type_="foreignkey")
    op.create_foreign_key(
        "text_work_language_id_fkey", "text_work", "language", ["language_id"], ["id"], ondelete="RESTRICT"
    )

    # SourceDoc -> GrammarTopic should be RESTRICT
    op.drop_constraint("grammar_topic_source_id_fkey", "grammar_topic", type_="foreignkey")
    op.create_foreign_key(
        "grammar_topic_source_id_fkey",
        "grammar_topic",
        "source_doc",
        ["source_id"],
        ["id"],
        ondelete="RESTRICT",
    )


def downgrade() -> None:
    """Revert CASCADE/RESTRICT behaviors to NO ACTION."""
    # Revert to default NO ACTION behavior
    op.drop_constraint("grammar_topic_source_id_fkey", "grammar_topic", type_="foreignkey")
    op.create_foreign_key(
        "grammar_topic_source_id_fkey", "grammar_topic", "source_doc", ["source_id"], ["id"]
    )

    op.drop_constraint("text_work_language_id_fkey", "text_work", type_="foreignkey")
    op.create_foreign_key("text_work_language_id_fkey", "text_work", "language", ["language_id"], ["id"])

    op.drop_constraint("text_work_source_id_fkey", "text_work", type_="foreignkey")
    op.create_foreign_key("text_work_source_id_fkey", "text_work", "source_doc", ["source_id"], ["id"])

    op.drop_constraint("text_segment_work_id_fkey", "text_segment", type_="foreignkey")
    op.create_foreign_key("text_segment_work_id_fkey", "text_segment", "text_work", ["work_id"], ["id"])
