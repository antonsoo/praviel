# Contributing to Ancient Languages

Thank you for your interest in contributing! This project welcomes contributions from developers, linguists, and language enthusiasts.

---

## Ways to Contribute

### 💻 **Code Contributions**

**Backend (Python/FastAPI):**
- Add new language support
- Improve retrieval accuracy
- Optimize database queries
- Add new API endpoints

**Frontend (Flutter):**
- Improve UI/UX
- Add mobile-specific features
- Enhance accessibility
- Optimize performance

**Data Pipelines:**
- Build TEI parsers for new languages
- Improve ingestion workflows
- Add support for new corpora

**See:** [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for technical setup

---

### 📚 **Linguistics Contributions**

**Language Reconstruction:**
- Validate phonology for reconstructed languages
- Review etymological accuracy
- Suggest authoritative sources

**Corpus Curation:**
- Identify high-quality public domain texts
- Create seed data (daily speech phrases)
- Build grammar reference mappings

**Pedagogy:**
- Improve lesson prompts
- Suggest exercise types
- Review learning progressions

**Expertise needed:** Classical languages, historical linguistics, pedagogy

---

### 📝 **Documentation Contributions**

**User Guides:**
- Write tutorials for beginners
- Create video walkthroughs
- Translate docs to other languages

**Technical Docs:**
- Improve API documentation
- Add code examples
- Write architecture diagrams

**Accessibility:**
- Screen reader testing
- Keyboard navigation improvements
- Color contrast audits

---

### 🧪 **Testing Contributions**

**Manual Testing:**
- Try new features
- Report bugs with detailed reproduction steps
- Test on different platforms (Windows, Mac, Linux, mobile)

**Automated Testing:**
- Write unit tests
- Add integration tests
- Improve accuracy test coverage

---

### 🗳️ **Community Contributions**

**Language Requests:**
- Vote for which languages to add next
- Share use cases and motivation
- Discuss in [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions)

**User Support:**
- Answer questions in Discussions
- Help troubleshoot issues
- Share learning tips

---

## Getting Started

### 1. Choose Your Contribution Type

- **Code:** Set up dev environment → [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- **Linguistics:** Join discussions → [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions)
- **Documentation:** Pick an issue labeled `docs` → [Issues](https://github.com/antonsoo/AncientLanguages/issues?q=is%3Aissue+is%3Aopen+label%3Adocs)
- **Testing:** Pick an issue labeled `good first issue` → [Issues](https://github.com/antonsoo/AncientLanguages/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

### 2. Fork and Clone

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR-USERNAME/AncientLanguages
cd AncientLanguages
```

### 3. Create a Branch

```bash
git checkout -b feat/my-contribution
# or
git checkout -b fix/bug-description
# or
git checkout -b docs/documentation-improvement
```

**Branch naming conventions:**
- `feat/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `test/` - Testing improvements
- `refactor/` - Code refactoring
- `chore/` - Build, dependencies, etc.

### 4. Make Your Changes

Follow the project's coding standards:
- **Commits:** Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- **Formatting:** Ruff (`ruff format`)
- **Type hints:** Use where practical
- **Tests:** Add tests for new features

### 5. Test Your Changes

```bash
# Run tests
pytest -q

# Run linting
pre-commit run --all-files

# If you modified provider code
python validate_api_versions.py
```

### 6. Commit and Push

```bash
git add .
git commit -m "feat: add support for Ancient Aramaic"
git push origin feat/my-contribution
```

### 7. Create a Pull Request

1. Go to your fork on GitHub
2. Click "Pull Request"
3. Write a clear description:
   - **What** does this PR do?
   - **Why** is this change needed?
   - **How** did you test it?
4. Link related issues (e.g., "Closes #123")
5. Wait for review

---

## Code Review Process

1. **Automated checks:** CI must pass (pytest, pre-commit, accuracy gates)
2. **Manual review:** Maintainer reviews code
3. **Discussion:** Address feedback, make changes
4. **Approval:** Maintainer approves
5. **Merge:** Squash merge to main

**Response time:** We aim to review PRs within 3-5 days.

---

## Coding Standards

### Python (Backend)

**Style:**
- Follow PEP 8 (enforced by Ruff)
- Use type hints
- Write docstrings for public functions

**Example:**
```python
from typing import List, Optional

async def analyze_token(
    token: str,
    language_id: int,
    db: AsyncSession
) -> Optional[TokenAnalysis]:
    """
    Analyze a Greek token for lemma, morphology, and definitions.

    Args:
        token: The Greek word to analyze
        language_id: Database ID of the language
        db: Async database session

    Returns:
        TokenAnalysis if found, None otherwise
    """
    # Implementation...
```

**Testing:**
```python
import pytest

@pytest.mark.asyncio
async def test_analyze_token_basic():
    """Test basic token analysis with known lemma."""
    result = await analyze_token("λόγος", language_id=1, db=db_session)
    assert result is not None
    assert result.lemma == "λόγος"
```

### Dart (Flutter)

**Style:**
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze`
- Write widget tests

**Example:**
```dart
/// Displays a Greek token with tap-to-analyze functionality.
class GreekTokenWidget extends StatelessWidget {
  const GreekTokenWidget({
    Key? key,
    required this.token,
    required this.onTap,
  }) : super(key: key);

  final String token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        token,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
```

---

## Commit Message Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/):

**Format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `chore`: Build, dependencies, etc.
- `perf`: Performance improvements

**Examples:**
```
feat(lessons): add support for Ancient Hebrew seed data

fix(reader): correct LSJ lookup for compounds

docs(api): add examples for lesson generation endpoint

test(retrieval): add accuracy tests for hybrid search

refactor(db): optimize token query with eager loading

chore(deps): update FastAPI to 0.104.0
```

---

## Linguistics Contribution Guidelines

### Adding a New Language

1. **Research Phase:**
   - Identify authoritative sources (corpora, lexicons, grammars)
   - Verify licensing (must be open or public domain)
   - Document reconstruction approach (for ancient languages)

2. **Proposal:**
   - Open a Discussion with:
     - Language name and historical period
     - Source texts you'll use
     - Lexicon/grammar references
     - Licensing information
   - Get community feedback

3. **Implementation:**
   - Create corpus pipeline
   - Add seed data (daily speech phrases)
   - Build lexicon/grammar mappings
   - Test thoroughly

4. **Validation:**
   - Get feedback from classicists/linguists
   - Run accuracy tests
   - Document any speculative reconstructions

### Reviewing Existing Content

- **Phonology:** Suggest improvements based on latest research
- **Etymology:** Cite authoritative sources
- **Grammar:** Reference standard works (like Smyth for Greek)

**All linguistic contributions should cite sources.**

---

## Community Guidelines

### Code of Conduct

We follow the [Contributor Covenant](https://www.contributor-covenant.org/):

- **Be respectful:** Treat all contributors with kindness
- **Be inclusive:** Welcome diverse perspectives
- **Be collaborative:** Help each other learn and grow
- **Be constructive:** Focus on improving the project

**Unacceptable behavior:**
- Harassment, discrimination, or abuse
- Trolling, insulting, or derogatory comments
- Personal or political attacks
- Publishing others' private information

**Reporting:** Report Code of Conduct violations via [GitHub Issues](https://github.com/antonsoo/AncientLanguages/issues) (mark as confidential) or email the repository owner directly through GitHub.

### Communication Channels

- **GitHub Discussions:** General questions, language requests, ideas
- **GitHub Issues:** Bug reports, feature requests
- **Pull Requests:** Code review, implementation discussion

**Be patient:** Maintainers are volunteers. Response times vary.

---

## Special Guidelines

### API Provider Changes

⚠️ **CRITICAL:** This repo uses October 2025 APIs.

Before modifying provider code:

1. Read [AGENTS.md](AGENTS.md)
2. Read [docs/AI_AGENT_GUIDELINES.md](docs/AI_AGENT_GUIDELINES.md)
3. Run `python scripts/validate_october_2025_apis.py`
4. Test with real APIs: `python validate_api_versions.py`

**DO NOT:**
- Change GPT-5 to use `/v1/chat/completions` (use `/v1/responses`)
- Change `max_output_tokens` to `max_tokens`
- Revert to pre-October 2025 patterns

**Protected files:** See [.github/CODEOWNERS](.github/CODEOWNERS)

### Data Contributions

**DO NOT commit:**
- Third-party corpora to `data/vendor/`
- Derived outputs to `data/derived/`
- API keys or secrets

**DO commit:**
- Fetch scripts for public domain sources
- Documentation of licensing
- Seed data you've authored (under Apache-2.0)

---

## Recognition

Contributors are recognized in:
- Git commit history
- Pull request credits
- Future CONTRIBUTORS.md file (coming soon)
- Release notes (for significant contributions)

---

## Questions?

- **How to contribute:** [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions)
- **Technical setup:** [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- **Project vision:** [BIG-PICTURE_PROJECT_PLAN.md](BIG-PICTURE_PROJECT_PLAN.md)

---

**Thank you for contributing to preserving and revitalizing ancient languages!**
