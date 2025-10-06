# External Libraries Setup

This document describes external library dependencies that are cloned separately from the main repository.

## CLTK (Classical Language Toolkit)

**Purpose**: Provides Greek lemmatization and text processing capabilities for the Ancient Languages app.

**Location**: `libraries/cltk/` (gitignored - not part of main repo)

**Repository**: https://github.com/cltk/cltk.git

**Used In**:
- `backend/app/ling/morph.py` - Greek lemmatization via `GreekBackoffLemmatizer`
- `backend/app/tests/test_lesson_quality.py` - Text normalization

**Installation**:
```bash
# Clone the CLTK library to the libraries directory
mkdir -p libraries
cd libraries
git clone https://github.com/cltk/cltk.git
cd cltk

# Install in development mode
pip install -e .
```

**Why Separate?**
- CLTK is an external dependency with its own release cycle
- Large repository with extensive documentation and datasets
- Already available via PyPI, but local clone allows for custom modifications if needed
- Kept in `libraries/` directory which is gitignored to avoid repo bloat

**Alternative Installation**:
If you don't need to modify CLTK, install directly from PyPI:
```bash
pip install cltk
```

## Directory Structure
```
AncientLanguages/
├── libraries/           # External library clones (gitignored)
│   └── cltk/           # CLTK library clone
├── backend/
│   ├── app/
│   └── cltk_data/      # CLTK downloaded models (gitignored)
└── ...
```

## Notes
- The `libraries/` directory is excluded via `.gitignore`
- CLTK data models are downloaded to `backend/cltk_data/` (also gitignored)
- Both directories are populated during development/build time
- See `pyproject.toml` for the CLTK version constraint if using PyPI installation
