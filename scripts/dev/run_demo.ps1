#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
Set-Location $root

docker compose up -d db
python -m alembic -c alembic.ini upgrade head

Push-Location client/flutter_reader
flutter build web
Pop-Location

$env:PYTHONPATH = 'backend'
$env:SERVE_FLUTTER_WEB = '1'
$env:ALLOW_DEV_CORS = '1'

uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
