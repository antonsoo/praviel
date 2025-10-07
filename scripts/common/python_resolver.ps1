# Common Python resolver for AncientLanguages project
# This module ensures all scripts use the correct Python version (3.12.x from conda env)

$ErrorActionPreference = 'Stop'

# Project Python requirements
$RequiredMajor = 3
$RequiredMinor = 12
$PreferredCondaEnv = 'ancient-languages-py312'

function Get-ProjectPythonCommand {
    <#
    .SYNOPSIS
    Resolves the correct Python command for the AncientLanguages project.

    .DESCRIPTION
    This function enforces Python 3.12.x usage by:
    1. Checking $env:UVICORN_PYTHON (manual override)
    2. Checking if current conda env matches requirements
    3. Trying to activate the preferred conda env
    4. Falling back to any Python 3.12.x in PATH
    5. Throwing an error if no suitable Python is found

    .OUTPUTS
    String path to the correct Python executable

    .EXAMPLE
    $python = Get-ProjectPythonCommand
    & $python -m pytest
    #>

    # 1. Check for manual override
    if ($env:UVICORN_PYTHON) {
        $pythonPath = $env:UVICORN_PYTHON
        if (Test-PythonVersion -PythonPath $pythonPath) {
            Write-Verbose "Using UVICORN_PYTHON override: $pythonPath"
            return $pythonPath
        } else {
            Write-Warning "UVICORN_PYTHON set but doesn't meet version requirements. Searching for alternative..."
        }
    }

    # 2. Check if we're already in a suitable conda environment
    if ($env:CONDA_DEFAULT_ENV) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCmd -and $pythonCmd.Source) {
            $pythonPath = $pythonCmd.Source
            if (Test-PythonVersion -PythonPath $pythonPath) {
                Write-Verbose "Using Python from active conda env: $env:CONDA_DEFAULT_ENV"
                return $pythonPath
            }
        }
    }

    # 3. Try to find Python in the preferred conda environment
    $condaPython = Find-CondaEnvPython -EnvName $PreferredCondaEnv
    if ($condaPython) {
        Write-Verbose "Found Python in conda env '$PreferredCondaEnv': $condaPython"
        return $condaPython
    }

    # 4. Fall back to searching PATH for any Python 3.12.x
    $candidates = @('python', 'python3', 'py')
    foreach ($candidate in $candidates) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and $cmd.Source -notlike '*WindowsApps*') {
            if (Test-PythonVersion -PythonPath $cmd.Source) {
                Write-Warning "Using Python from PATH: $($cmd.Source)"
                Write-Warning "Consider activating conda environment '$PreferredCondaEnv' for best compatibility"
                return $cmd.Source
            }
        }
    }

    # 5. No suitable Python found
    throw @"
ERROR: No suitable Python found.

Required: Python $RequiredMajor.$RequiredMinor.x
Preferred: conda environment '$PreferredCondaEnv'

To fix:
1. Activate conda environment: conda activate $PreferredCondaEnv
2. Or set UVICORN_PYTHON to point to Python 3.12.x
3. Or ensure Python 3.12.x is in PATH

Current environment:
  CONDA_DEFAULT_ENV: $(if ($env:CONDA_DEFAULT_ENV) { $env:CONDA_DEFAULT_ENV } else { 'not set' })
  PATH Python: $(
    $pathPython = Get-Command python -ErrorAction SilentlyContinue
    if ($pathPython -and $pathPython.Source) { $pathPython.Source } else { 'not found' }
)
"@
}

function Test-PythonVersion {
    <#
    .SYNOPSIS
    Tests if a Python executable meets version requirements.

    .PARAMETER PythonPath
    Path to Python executable

    .OUTPUTS
    Boolean indicating if version is acceptable
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonPath
    )

    if (-not (Test-Path $PythonPath)) {
        return $false
    }

    try {
        # Get Python version
        $versionOutput = & $PythonPath --version 2>&1 | Out-String
        if ($versionOutput -match 'Python (\d+)\.(\d+)\.(\d+)') {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]

            $meetsRequirement = ($major -eq $RequiredMajor) -and ($minor -eq $RequiredMinor)

            if ($meetsRequirement) {
                Write-Verbose "Python version check passed: $versionOutput"
            } else {
                Write-Verbose "Python version mismatch: found $major.$minor, need $RequiredMajor.$RequiredMinor"
            }

            return $meetsRequirement
        } else {
            Write-Verbose "Could not parse Python version from: $versionOutput"
            return $false
        }
    } catch {
        Write-Verbose "Error checking Python version: $_"
        return $false
    }
}

function Find-CondaEnvPython {
    <#
    .SYNOPSIS
    Finds Python executable in a specific conda environment.

    .PARAMETER EnvName
    Name of the conda environment

    .OUTPUTS
    String path to Python executable, or $null if not found
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvName
    )

    # Try common conda installation locations
    $condaRoots = @(
        'C:\ProgramData\anaconda3',
        'C:\Users\*\anaconda3',
        'C:\Users\*\miniconda3',
        "$env:USERPROFILE\anaconda3",
        "$env:USERPROFILE\miniconda3",
        "$env:CONDA_PREFIX\.."
    )

    foreach ($root in $condaRoots) {
        $envPaths = @(
            "$root\envs\$EnvName\python.exe",
            "$root\envs\$EnvName\Scripts\python.exe"
        )

        foreach ($path in $envPaths) {
            # Resolve wildcards
            $resolved = Get-Item -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($resolved -and (Test-PythonVersion -PythonPath $resolved.FullName)) {
                return $resolved.FullName
            }
        }
    }

    return $null
}

function Assert-ProjectPython {
    <#
    .SYNOPSIS
    Validates that the current Python meets project requirements and throws if not.

    .DESCRIPTION
    Use this at the start of scripts to ensure correct Python version.
    More strict than Get-ProjectPythonCommand - requires exact environment.
    #>

    $python = Get-ProjectPythonCommand

    # Additional check: warn if not in preferred conda env
    if ($env:CONDA_DEFAULT_ENV -ne $PreferredCondaEnv) {
        $currentEnv = if ($env:CONDA_DEFAULT_ENV) { $env:CONDA_DEFAULT_ENV } else { 'none' }
        Write-Warning @"
Python version is correct, but you're not in the preferred conda environment.
Current: $currentEnv
Preferred: $PreferredCondaEnv

Some dependencies may not be available. Consider running:
  conda activate $PreferredCondaEnv
"@
    }

    return $python
}
