# AncientLanguages — Text Corpus Sources & Provenance

**Version:** 1.0
**Last Updated:** 2025-10-16

This document provides detailed provenance information for all classical texts included in the AncientLanguages Reader feature, ensuring reproducibility and legal compliance.

---

## Purpose

This document serves to:
1. **Ensure transparency**: Users know exactly where texts come from
2. **Enable reproducibility**: Researchers can verify and reproduce our text corpus
3. **Legal compliance**: Proper attribution for CC BY-SA 3.0 and other licenses
4. **Track updates**: Document when texts were added/updated

---

## General Principles

### Source Selection Criteria
All texts included in AncientLanguages must meet these criteria:
- **Public domain** OR **openly licensed** (CC BY-SA, CC0, etc.)
- **High scholarly quality**: Preference for Perseus, OpenGreekAndLatin, CLTK corpora
- **Machine-readable format**: TEI XML, JSON, or plain text with metadata
- **Reproducible**: Specific commit hashes or version numbers documented

### Attribution Requirements
- All texts are attributed to their source in the app UI (Reader screen footer)
- License information is displayed when users first access the Reader
- Full attribution is included in exported texts (future feature)

---

## Text Corpus: Ancient Greek (grc)

### 1. Homer — Iliad

**Author**: Homer (Ὅμηρος)
**Title**: Iliad (Ἰλιάς)
**Language**: Ancient Greek (grc)
**Date of Composition**: ~8th century BCE

**Source Information**:
- **Repository**: Perseus Digital Library — Canonical Greek Lit
- **GitHub URL**: https://github.com/PerseusDL/canonical-greekLit
- **File Path**: `data/tlg0012/tlg001/tlg0012.tlg001.perseus-grc2.xml`
- **CTS URN**: `urn:cts:greekLit:tlg0012.tlg001.perseus-grc2`
- **Editor**: Thomas W. Allen (Oxford Classical Texts, 1920)
- **Commit Hash**: `[To be filled when downloaded]`
- **Download Date**: 2025-10-16

**License**:
- **Type**: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
- **URL**: https://creativecommons.org/licenses/by-sa/3.0/

**Coverage**:
- **Books**: 1-24 (complete)
- **Lines**: 15,693 total
- **Current database**: Book 1 only (611 lines) — Books 2-24 to be added

**Scholarly Notes**:
- Text based on Thomas W. Allen's Oxford Classical Text (1920)
- Some variant readings may differ from other editions (e.g., Monro-Allen 1902)
- Perseus includes critical apparatus (not currently imported into our database)

**Reference Scheme**: `book.line` (e.g., `Il.1.1`, `Il.2.477`)

**Local File**: `backend/data/iliad_grc.xml`

---

### 2. Homer — Odyssey

**Author**: Homer (Ὅμηρος)
**Title**: Odyssey (Ὀδύσσεια)
**Language**: Ancient Greek (grc)
**Date of Composition**: ~8th century BCE

**Source Information**:
- **Repository**: Perseus Digital Library — Canonical Greek Lit
- **GitHub URL**: https://github.com/PerseusDL/canonical-greekLit
- **File Path**: `data/tlg0012/tlg002/tlg0012.tlg002.perseus-grc2.xml`
- **CTS URN**: `urn:cts:greekLit:tlg0012.tlg002.perseus-grc2`
- **Editor**: Thomas W. Allen (Oxford Classical Texts, 1919)
- **Commit Hash**: `[To be filled when downloaded]`
- **Download Date**: [To be filled]

**License**:
- **Type**: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
- **URL**: https://creativecommons.org/licenses/by-sa/3.0/

**Coverage**:
- **Books**: 1-24 (complete)
- **Lines**: 12,109 total
- **Current database**: Not yet imported

**Reference Scheme**: `book.line` (e.g., `Od.1.1`, `Od.9.19`)

**Local File**: `backend/data/odyssey_grc.xml` (to be added)

**Status**: 🚧 **TO BE ADDED** (Phase 1 of implementation)

---

### 3. Plato — Apology

**Author**: Plato (Πλάτων)
**Title**: Apology of Socrates (Ἀπολογία Σωκράτους)
**Language**: Ancient Greek (grc)
**Date of Composition**: ~399-390 BCE

**Source Information**:
- **Repository**: Perseus Digital Library — Canonical Greek Lit
- **GitHub URL**: https://github.com/PerseusDL/canonical-greekLit
- **File Path**: `data/tlg0059/tlg002/tlg0059.tlg002.perseus-grc2.xml`
- **CTS URN**: `urn:cts:greekLit:tlg0059.tlg002.perseus-grc2`
- **Editor**: John Burnet (Oxford Classical Texts, 1903)
- **Commit Hash**: `[To be filled]`
- **Download Date**: [To be filled]

**License**:
- **Type**: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
- **URL**: https://creativecommons.org/licenses/by-sa/3.0/

**Coverage**:
- **Stephanus Pages**: 17a - 42a
- **Sections**: ~120 segments (varies by edition)
- **Current database**: Not yet imported

**Reference Scheme**: `stephanus` (e.g., `Apol.17a`, `Apol.23c`)

**Local File**: `backend/data/plato_apology_grc.xml` (to be added)

**Status**: 🚧 **TO BE ADDED** (Phase 1 of implementation)

---

### 4. Plato — Symposium

**Author**: Plato (Πλάτων)
**Title**: Symposium (Συμπόσιον)
**Language**: Ancient Greek (grc)
**Date of Composition**: ~385-370 BCE

**Source Information**:
- **Repository**: Perseus Digital Library — Canonical Greek Lit
- **GitHub URL**: https://github.com/PerseusDL/canonical-greekLit
- **File Path**: `data/tlg0059/tlg017/tlg0059.tlg017.perseus-grc2.xml`
- **CTS URN**: `urn:cts:greekLit:tlg0059.tlg017.perseus-grc2`
- **Editor**: John Burnet (Oxford Classical Texts, 1903)
- **Commit Hash**: `[To be filled]`
- **Download Date**: [To be filled]

**License**:
- **Type**: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
- **URL**: https://creativecommons.org/licenses/by-sa/3.0/

**Coverage**:
- **Stephanus Pages**: 172a - 223d
- **Sections**: ~250 segments (varies by edition)
- **Current database**: Not yet imported

**Reference Scheme**: `stephanus` (e.g., `Symp.172a`, `Symp.201d`)

**Local File**: `backend/data/plato_symposium_grc.xml` (to be added)

**Status**: 🚧 **TO BE ADDED** (Phase 1 of implementation)

---

### 5. Plato — Republic (Book 1)

**Author**: Plato (Πλάτων)
**Title**: Republic (Πολιτεία), Book 1
**Language**: Ancient Greek (grc)
**Date of Composition**: ~380-375 BCE

**Source Information**:
- **Repository**: Perseus Digital Library — Canonical Greek Lit
- **GitHub URL**: https://github.com/PerseusDL/canonical-greekLit
- **File Path**: `data/tlg0059/tlg030/tlg0059.tlg030.perseus-grc2.xml`
- **CTS URN**: `urn:cts:greekLit:tlg0059.tlg030.perseus-grc2`
- **Editor**: John Burnet (Oxford Classical Texts, 1903)
- **Commit Hash**: `[To be filled]`
- **Download Date**: [To be filled]

**License**:
- **Type**: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
- **URL**: https://creativecommons.org/licenses/by-sa/3.0/

**Coverage**:
- **Stephanus Pages**: 327a - 354c (Book 1 only)
- **Sections**: ~150 segments (varies by edition)
- **Current database**: Not yet imported
- **Note**: We are including only Book 1 initially (Books 2-10 may be added later)

**Reference Scheme**: `stephanus` (e.g., `Rep.1.327a`, `Rep.1.354c`)

**Local File**: `backend/data/plato_republic_book1_grc.xml` (to be added)

**Status**: 🚧 **TO BE ADDED** (Phase 1 of implementation)

---

## Supporting Resources

### Lexicon: Liddell-Scott-Jones (LSJ)

**Title**: A Greek-English Lexicon (9th edition, 1940)
**Authors**: Henry George Liddell, Robert Scott, Henry Stuart Jones
**Publisher**: Clarendon Press, Oxford

**Source Information**:
- **Repository**: Perseus Digital Library
- **URL**: http://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.04.0057
- **Format**: Proprietary Perseus XML (not TEI)
- **License**: Public domain (pre-1923 publication, copyright expired in U.S.)

**Coverage**:
- ~116,000 entries
- Classical Greek through Byzantine era
- **Current database**: Partial import (common vocabulary only)

**Status**: ✅ **Partially integrated** (used in Reader for word lookups)

---

### Grammar: Smyth's Greek Grammar

**Title**: A Greek Grammar for Colleges (1920)
**Author**: Herbert Weir Smyth
**Publisher**: American Book Company

**Source Information**:
- **Repository**: Perseus Digital Library
- **URL**: http://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.04.0007
- **Format**: HTML (converted from scanned text)
- **License**: Public domain (pre-1923 publication)

**Coverage**:
- ~2,800 numbered sections
- Covers phonology, morphology, syntax
- **Current database**: Partial import (referenced in grammar exercises)

**Status**: ✅ **Partially integrated** (used in lessons and Reader for grammar references)

---

## Future Additions (Planned)

### Latin Texts (To Be Added)

| Author | Title | Source | License | Status |
|--------|-------|--------|---------|--------|
| Virgil | Aeneid | Perseus | CC BY-SA 3.0 | 🚧 Planned |
| Caesar | Gallic Wars | Perseus | CC BY-SA 3.0 | 🚧 Planned |
| Cicero | Catilinarian Orations | Perseus | CC BY-SA 3.0 | 🚧 Planned |

### Biblical Hebrew (To Be Added)

| Text | Source | License | Status |
|------|--------|---------|--------|
| Genesis | Westminster Leningrad Codex | Public domain | 🚧 Planned |
| Psalms | Westminster Leningrad Codex | Public domain | 🚧 Planned |

### Sanskrit (To Be Added)

| Author | Title | Source | License | Status |
|--------|-------|--------|---------|--------|
| Vyasa | Bhagavad Gita | GRETIL | Public domain | 🚧 Planned |

---

## Data Processing Pipeline

### How Texts Are Imported

1. **Download XML from Perseus GitHub** (specific commit hash)
2. **Parse TEI XML** (`backend/scripts/seed_perseus_content.py`)
3. **Normalize Unicode** (NFC normalization)
4. **Create folded text** (lowercase, remove accents for search)
5. **Populate database tables**:
   - `language` (e.g., "grc")
   - `source_doc` (metadata, license info)
   - `text_work` (author, title, ref_scheme)
   - `text_segment` (individual lines/paragraphs with refs)
6. **Tokenize** (future: populate `token` table with lemmas)
7. **Generate embeddings** (future: populate `text_segment.emb` for semantic search)

**Script**: `backend/scripts/seed_perseus_content.py`

**Command**:
```bash
python backend/scripts/seed_perseus_content.py
```

---

## Verification & Quality Assurance

### Checksums (To Be Added)
For reproducibility, we will provide SHA256 checksums of all source XML files:

```
# Example (to be filled):
sha256sum backend/data/iliad_grc.xml
# Expected output: [hash] backend/data/iliad_grc.xml
```

### Diff Against Original
To verify our processing hasn't corrupted texts:
```bash
# Compare line counts
wc -l backend/data/iliad_grc.xml
# Expected: 15,693 lines (excluding XML tags)
```

### Manual Spot Checks
Random passages are manually verified against:
- **Perseus web interface**: http://www.perseus.tufts.edu/
- **Scaife Viewer**: https://scaife.perseus.org/
- **Printed editions**: Oxford Classical Texts (when available)

---

## License Compliance Checklist

- [x] All texts are CC BY-SA 3.0 or public domain
- [x] Attribution to Perseus Digital Library in app UI
- [x] License information displayed in Reader feature
- [ ] Export feature includes attribution (future work)
- [ ] User-uploaded texts have license verification (future work)

---

## Contact & Updates

### Report Issues
- **Missing attribution**: antonnsoloviev@gmail.com
- **Text errors/corruption**: Open issue at https://github.com/antonsoo/AncientLanguages/issues
- **License questions**: antonnsoloviev@gmail.com

### Update Frequency
- This document is updated whenever new texts are added or existing texts are updated
- Check the "Last Updated" date at the top

---

## Appendix: TLG (Thesaurus Linguae Graecae) Codes

Perseus texts are referenced by TLG author and work codes:

| Code | Author | Work | Perseus ID |
|------|--------|------|------------|
| tlg0012 | Homer | - | - |
| tlg0012.tlg001 | Homer | Iliad | urn:cts:greekLit:tlg0012.tlg001 |
| tlg0012.tlg002 | Homer | Odyssey | urn:cts:greekLit:tlg0012.tlg002 |
| tlg0059 | Plato | - | - |
| tlg0059.tlg002 | Plato | Apology | urn:cts:greekLit:tlg0059.tlg002 |
| tlg0059.tlg017 | Plato | Symposium | urn:cts:greekLit:tlg0059.tlg017 |
| tlg0059.tlg030 | Plato | Republic | urn:cts:greekLit:tlg0059.tlg030 |

**Reference**: http://stephanus.tlg.uci.edu/

---

**Document Version**: 1.0
**Last Updated**: 2025-10-16
**Maintainer**: Anton Soloviev (antonnsoloviev@gmail.com)

© 2025 Anton Soloviev (AncientLanguages documentation). Texts © Perseus Digital Library (CC BY-SA 3.0).
