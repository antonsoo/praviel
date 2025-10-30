param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArgs = @()
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')

Push-Location $repoRoot
try {
    docker compose up -d db
    python -m alembic -c alembic.ini upgrade head
    python scripts/ingest_iliad_sample.py @ScriptArgs
}
finally {
    Pop-Location
}
