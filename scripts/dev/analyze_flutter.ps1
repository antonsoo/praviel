#!/usr/bin/env pwsh

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
$artifactDir = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null

Push-Location (Join-Path $root 'client/flutter_reader')
flutter pub get | Out-Null
$analyzePath = Join-Path $artifactDir 'dart_analyze.json'
dart analyze --format=json | Set-Content -Encoding UTF8 -Path $analyzePath
Pop-Location
