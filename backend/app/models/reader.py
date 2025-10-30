"""Pydantic models for Reader API endpoints."""

from pydantic import BaseModel, Field


class TextWorkInfo(BaseModel):
    """Information about a text work (book, dialogue, etc.)."""

    id: int = Field(..., description="Database ID of the work")
    author: str = Field(..., description="Author name (e.g., 'Homer', 'Plato')")
    title: str = Field(..., description="Work title (e.g., 'Iliad', 'Apology')")
    language: str = Field(..., description="Language code (e.g., 'grc' for Ancient Greek)")
    ref_scheme: str = Field(
        ..., description="Reference scheme (e.g., 'book.line', 'stephanus', 'chapter.verse')"
    )
    segment_count: int = Field(..., description="Total number of text segments (lines, pages, verses)")
    license_name: str = Field(..., description="License name (e.g., 'CC BY-SA 3.0')")
    license_url: str | None = Field(None, description="URL to full license text")
    source_title: str = Field(..., description="Source document title (e.g., 'Perseus Digital Library')")
    preview: str | None = Field(None, description="Short preview snippet of the work")

    model_config = {"from_attributes": True}


class BookInfo(BaseModel):
    """Information about a book within a work (for book.line reference scheme)."""

    book: int = Field(..., description="Book number")
    line_count: int = Field(..., description="Number of lines in this book")
    first_line: int = Field(..., description="First line number")
    last_line: int = Field(..., description="Last line number")


class TextStructure(BaseModel):
    """Structural metadata for a text work."""

    text_id: int = Field(..., description="Database ID of the work")
    title: str = Field(..., description="Work title")
    author: str = Field(..., description="Author name")
    ref_scheme: str = Field(..., description="Reference scheme")

    # For book.line scheme (Homer):
    books: list[BookInfo] | None = Field(None, description="Book metadata (for book.line scheme)")

    # For stephanus scheme (Plato):
    pages: list[str] | None = Field(None, description="Stephanus page list (for stephanus scheme)")

    # For other schemes (future):
    chapters: list[dict] | None = Field(None, description="Chapter metadata (for chapter.verse scheme)")


class SegmentWithMeta(BaseModel):
    """A text segment with its metadata."""

    ref: str = Field(..., description="Reference (e.g., 'Il.1.1', 'Apol.17a')")
    text: str = Field(..., description="Greek text content")
    meta: dict = Field(..., description="Metadata (e.g., {'book': 1, 'line': 1} or {'page': '17a'})")

    model_config = {"from_attributes": True}


class TextListResponse(BaseModel):
    """Response for GET /reader/texts."""

    texts: list[TextWorkInfo] = Field(..., description="List of available text works")


class TextStructureResponse(BaseModel):
    """Response for GET /reader/texts/{id}/structure."""

    structure: TextStructure = Field(..., description="Structural metadata for the text")


class TextSegmentsRequest(BaseModel):
    """Request for GET /reader/texts/{id}/segments."""

    ref_start: str = Field(..., description="Starting reference (e.g., 'Il.1.1', 'Apol.17a')")
    ref_end: str = Field(..., description="Ending reference (e.g., 'Il.1.50', 'Apol.20e')")


class TextSegmentsResponse(BaseModel):
    """Response for GET /reader/texts/{id}/segments."""

    segments: list[SegmentWithMeta] = Field(..., description="List of text segments in the range")
    text_info: dict = Field(..., description="Metadata about the text (author, title, license)")
