"""Pydantic schemas for script display preferences.

These schemas define user preferences for how ancient language texts are rendered.
"""

from pydantic import BaseModel, Field


class ScriptDisplayMode(BaseModel):
    """Script display mode configuration for a specific language."""

    # Word separation modes
    use_scriptio_continua: bool = Field(
        default=False,
        description="Remove all word spaces (continuous writing as ancients wrote)",
    )
    use_interpuncts: bool = Field(
        default=False,
        description="Replace spaces with interpuncts (·) for inscription-style display",
    )

    # Greek-specific options
    use_iota_adscript: bool = Field(
        default=True,
        description="Convert iota subscripts to full iota (ᾳ → ΑΙ, ῳ → ΩΙ)",
    )

    # Koine Greek specific
    use_nomina_sacra: bool = Field(
        default=False,
        description="Apply nomina sacra abbreviations with overlines (Θ͞Σ͞ for ΘΕΟΣ)",
    )

    # Punctuation
    remove_modern_punctuation: bool = Field(
        default=False,
        description="Remove modern punctuation marks (?, !, commas, etc.)",
    )

    class Config:
        json_schema_extra = {
            "example": {
                "use_scriptio_continua": False,
                "use_interpuncts": True,
                "use_iota_adscript": True,
                "use_nomina_sacra": False,
                "remove_modern_punctuation": False,
            }
        }


class ScriptPreferences(BaseModel):
    """User preferences for script rendering across all languages."""

    # Global authentic mode toggle
    authentic_mode: bool = Field(
        default=False,
        description=(
            "Master toggle for authentic ancient scripts. When enabled, uses historically "
            "accurate rendering (uppercase, no accents, etc.) based on language config."
        ),
    )

    # Per-language overrides
    latin: ScriptDisplayMode = Field(
        default_factory=ScriptDisplayMode,
        description="Script display settings for Classical Latin (lat)",
    )
    greek_classical: ScriptDisplayMode = Field(
        default_factory=ScriptDisplayMode,
        description="Script display settings for Classical Greek (grc)",
    )
    greek_koine: ScriptDisplayMode = Field(
        default_factory=ScriptDisplayMode,
        description="Script display settings for Koine Greek (grc-koi)",
    )

    class Config:
        json_schema_extra = {
            "example": {
                "authentic_mode": True,
                "latin": {
                    "use_scriptio_continua": False,
                    "use_interpuncts": True,
                    "use_iota_adscript": False,
                    "use_nomina_sacra": False,
                    "remove_modern_punctuation": True,
                },
                "greek_classical": {
                    "use_scriptio_continua": False,
                    "use_interpuncts": False,
                    "use_iota_adscript": True,
                    "use_nomina_sacra": False,
                    "remove_modern_punctuation": True,
                },
                "greek_koine": {
                    "use_scriptio_continua": False,
                    "use_interpuncts": False,
                    "use_iota_adscript": True,
                    "use_nomina_sacra": True,
                    "remove_modern_punctuation": True,
                },
            }
        }


class ScriptPreferencesUpdate(BaseModel):
    """Schema for updating script preferences (all fields optional)."""

    authentic_mode: bool | None = None
    latin: ScriptDisplayMode | None = None
    greek_classical: ScriptDisplayMode | None = None
    greek_koine: ScriptDisplayMode | None = None
