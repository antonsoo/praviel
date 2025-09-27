#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$runner = Join-Path $root 'scripts/dev/_step_runner.py'

function Resolve-Python {
    $candidates = @('python', 'python3')
    foreach ($name in $candidates) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command -and $command.Source -and -not ($command.Source -like '*WindowsApps*')) {
            return $command.Source
        }
    }

    $launcher = Get-Command py -ErrorAction SilentlyContinue
    if ($launcher) {
        foreach ($version in @('-3.12', '-3')) {
            try {
                $resolved = (& $launcher.Source $version -c "import sys, pathlib; print(pathlib.Path(sys.executable).resolve())").Trim()
            } catch {
                $resolved = $null
            }
            if ($LASTEXITCODE -eq 0 -and $resolved -and (Test-Path $resolved)) {
                return $resolved
            }
        }
    }

    throw '[step] python is required to run the step runner.'
}

$python = Resolve-Python
& $python $runner @Args
exit $LASTEXITCODE
