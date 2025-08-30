from pydantic import BaseModel, Field
from typing import Dict

class TextIngestRequest(BaseModel):
    raw_content: str = Field(..., min_length=1, description="The raw text content to be processed and ingested.")
    overwrite_existing: bool = Field(default=False, description="If true, delete existing sentences/wordforms for this text before ingestion.")

class IngestionResponse(BaseModel):
    message: str
    text_id: int
    language_code: str
    stats: Dict[str, int] # e.g., {"sentences": 10, "words": 150}