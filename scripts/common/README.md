# Common Scripts

This directory contains shared utilities used across PowerShell scripts in the project.

## python_resolver.ps1

**Purpose**: Centralized Python version resolution to ensure all scripts use Python 3.12.11.

### Why This Exists

The project requires Python 3.12.11 from the `ancient-languages-py312` conda environment, but:
- Windows has Python 3.13.5 installed globally
- Agents and developers might run scripts without activating conda
- Multiple scripts needed Python resolution logic (code duplication)

### How It Works

The resolver implements a search strategy:

1. **Check `$env:UVICORN_PYTHON`** - Manual override for flexibility
2. **Check active conda environment** - If already activated, use it
3. **Search for Python in `ancient-languages-py312` conda env** - Project default
4. **Fall back to PATH** - Any Python 3.12.x (with warning)
5. **Throw error** - No suitable Python found

### Usage

```powershell
# At the top of your PowerShell script
. (Join-Path $PSScriptRoot '..\common\python_resolver.ps1')

# Get the correct Python executable
$python = Get-ProjectPythonCommand

# Use it
& $python -m pytest
& $python -m uvicorn app.main:app
```

### Functions

#### `Get-ProjectPythonCommand`

Returns the path to a suitable Python 3.12.x executable.

**Returns**: String path to Python executable
**Throws**: Error if no suitable Python found

#### `Test-PythonVersion`

Tests if a Python executable meets version requirements (3.12.x).

**Parameters**:
- `PythonPath` - Path to Python executable

**Returns**: Boolean

#### `Find-CondaEnvPython`

Searches for Python in a specific conda environment.

**Parameters**:
- `EnvName` - Name of conda environment

**Returns**: String path or `$null`

#### `Assert-ProjectPython`

Like `Get-ProjectPythonCommand` but also warns if not in preferred conda env.

**Returns**: String path to Python executable

### Scripts Using This Resolver

- `scripts/dev/serve_uvicorn.ps1`
- `scripts/dev/smoke_lessons.ps1`
- `scripts/dev/smoke_chat.ps1`
- `scripts/dev/run_mvp.ps1`
- `scripts/reset_db.ps1`

### Manual Override

If you need to use a different Python version:

```powershell
$env:UVICORN_PYTHON = 'C:\path\to\your\python.exe'
.\scripts\dev\smoke_lessons.ps1
```

### Compatibility

- **PowerShell**: 5.1+ (Windows PowerShell, PowerShell Core)
- **Platform**: Windows (conda env detection specific to Windows paths)
