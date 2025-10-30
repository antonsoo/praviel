[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$knownRoots = @('C:\\Program Files\\Git', 'C:\\Program Files (x86)\\Git')
$pathsToAdd = @()

foreach ($root in $knownRoots) {
    if (Test-Path $root) {
        $pathsToAdd += @(Join-Path $root 'usr\\bin', Join-Path $root 'bin')
    }
}

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($gitCommand) {
    $gitDir = (Get-Item $gitCommand.Source).Directory
    if ($gitDir) {
        $root = $gitDir.Parent
        if ($root) {
            $pathsToAdd += @(Join-Path $root.FullName 'usr\\bin', Join-Path $root.FullName 'bin')
        }
    }
}

$pathsToAdd = $pathsToAdd | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
$existing = ($env:PATH -split ';')
$added = @()
foreach ($candidate in $pathsToAdd) {
    if ($existing -notcontains $candidate) {
        $env:PATH = "$candidate;$($env:PATH)"
        $added += $candidate
    }
}

$shCommand = Get-Command sh.exe -ErrorAction SilentlyContinue
if (-not $shCommand) {
    $shCommand = Get-Command sh -ErrorAction SilentlyContinue
}
$bashCommand = Get-Command bash.exe -ErrorAction SilentlyContinue
if (-not $bashCommand) {
    $bashCommand = Get-Command bash -ErrorAction SilentlyContinue
}

if (-not $shCommand -or -not $bashCommand) {
    throw '[git-env] required Git shell binaries not found on PATH'
}

if ($added.Count -gt 0) {
    Write-Output ("[git-env] added {0} to PATH; sh={1}; bash={2}" -f ($added -join ', '), $shCommand.Source, $bashCommand.Source)
} else {
    Write-Output ("[git-env] PATH already includes Git directories; sh={0}; bash={1}" -f $shCommand.Source, $bashCommand.Source)
}
