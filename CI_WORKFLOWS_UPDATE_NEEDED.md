# CI Workflows - Manual Update Required

The following GitHub Actions workflow files need Python version updated from `3.12` to `3.13`:

## Files Requiring Update

1. **`.github/workflows/accuracy-comment.yml`** (line 59)
   ```yaml
   python-version: '3.12'  # Change to '3.13'
   ```

2. **`.github/workflows/accuracy.yml`** (line 49)
   ```yaml
   python-version: '3.12'  # Change to '3.13'
   ```

3. **`.github/workflows/bench-latency.yml`** (line 54)
   ```yaml
   python-version: '3.12'  # Change to '3.13'
   ```

## Already Updated

- ✅ `.github/workflows/ci.yml` - Linux job updated to Python 3.13
- ✅ `.github/workflows/ci.yml` - Flutter channel updated to `main`

## Windows CI Job

The Windows CI job in `.github/workflows/ci.yml` (lines 109-178) still exists and references:
- Python 3.12
- PowerShell scripts (`orchestrate.ps1`)

**Recommendation:** Since the project has fully migrated to Linux, consider either:
1. **Remove the Windows job entirely** (project no longer supports Windows)
2. **Keep it disabled** for backward compatibility but mark as deprecated

---

**Security Note:** The pre-commit hook blocked these edits as a security precaution for workflow files. These are safe changes (version updates only, no untrusted input handling).
