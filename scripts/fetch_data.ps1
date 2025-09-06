<#
Usage (run from repo root):
  pwsh -File scripts/fetch_data.ps1
  # optional treebank (large download)
  pwsh -File scripts/fetch_data.ps1 -IncludeAGLDT

This populates:
  data/vendor/perseus/iliad/tlg0012.tlg001.perseus-grc2.xml  (also copied to book1.xml)
  data/vendor/lsj/grc.lsj.perseus-eng13.xml
  data/vendor/smyth/smyth.html
  data/vendor/agldt/treebank_data/ ...  (only if -IncludeAGLDT)
#>

# If you ever want the test/CLI to work without renaming, you can also have the script copy the Perseus TEI to book1.xml if it doesn’t exist:
# Not required if you already have book1.xml
$iliadDir = Join-Path $VendorRoot "perseus\iliad"
$src = Join-Path $iliadDir "tlg0012.tlg001.perseus-grc2.xml"
$dst = Join-Path $iliadDir "book1.xml"
if (Test-Path $src -and -not (Test-Path $dst)) { Copy-Item $src $dst }

param(
  [switch]$IncludeAGLDT = $false
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ---- helpers ---------------------------------------------------------------
function New-Dir($p) { if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory | Out-Null } }

function Download-FirstOk {
  param(
    [Parameter(Mandatory=$true)][string[]]$Urls,
    [Parameter(Mandatory=$true)][string]$OutFile
  )
  foreach ($u in $Urls) {
    try {
      Write-Host "Downloading $u -> $OutFile"
      Invoke-WebRequest -Uri $u -OutFile $OutFile -UseBasicParsing -MaximumRedirection 5
      if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) { return $true }
    } catch { Write-Host "  failed: $u ($($_.Exception.Message))" }
  }
  throw "All URLs failed for $OutFile"
}

function Normalize-Utf8Lf {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path $Path)) { return }
  $raw = Get-Content -Raw -LiteralPath $Path
  # unify newlines
  $raw = $raw -replace "`r`n", "`n"
  # write UTF-8 without BOM
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Resolve-Path $Path), $raw, $utf8NoBom)
}

# ---- directories -----------------------------------------------------------
$repoRoot  = Resolve-Path (Join-Path $PSScriptRoot "..")
$dataRoot  = Join-Path $repoRoot "data"
$vendor    = Join-Path $dataRoot "vendor"
$derived   = Join-Path $dataRoot "derived"
$perseus   = Join-Path $vendor "perseus\iliad"
$lsj       = Join-Path $vendor "lsj"
$smyth     = Join-Path $vendor "smyth"
$agldt     = Join-Path $vendor "agldt"

New-Dir $dataRoot; New-Dir $vendor; New-Dir $derived
New-Dir $perseus;  New-Dir $lsj;    New-Dir $smyth;  New-Dir $agldt

# ---- Perseus/Scaife: Iliad TEI (Homer, tlg0012.tlg001.perseus-grc2.xml) ----
# primary (Perseus canonical-greekLit), fallback (OGL First1KGreek)
$iliadOut = Join-Path $perseus "tlg0012.tlg001.perseus-grc2.xml"
$iliadUrls = @(
  "https://raw.githubusercontent.com/PerseusDL/canonical-greekLit/master/data/tlg0012/tlg001/tlg0012.tlg001.perseus-grc2.xml",
  "https://raw.githubusercontent.com/OpenGreekAndLatin/First1KGreek/master/data/tlg0012/tlg001/tlg0012.tlg001.perseus-grc2.xml"
)
Download-FirstOk -Urls $iliadUrls -OutFile $iliadOut
Normalize-Utf8Lf -Path $iliadOut
# Convenience copy for the PR2 sample job
Copy-Item -Force $iliadOut (Join-Path $perseus "book1.xml")

# ---- LSJ TEI (PerseusDL/lexica) -------------------------------------------
$lsjOut = Join-Path $lsj "grc.lsj.perseus-eng13.xml"
$lsjUrls = @(
  "https://raw.githubusercontent.com/PerseusDL/lexica/master/CTS_XML_TEI/perseus/pdllex/grc/lsj/grc.lsj.perseus-eng13.xml",
  # fallback (community mirror/variant)
  "https://raw.githubusercontent.com/gcelano/LSJ_GreekUnicode/master/grc.lsj.perseus-eng19.xml"
)
Download-FirstOk -Urls $lsjUrls -OutFile $lsjOut
Normalize-Utf8Lf -Path $lsjOut

# ---- Smyth (Alpheios Perseus HTML snapshot) -------------------------------
$smythOut = Join-Path $smyth "smyth.html"
$smythUrls = @(
  "https://grammars.alpheios.net/smyth/xhtml/smyth.html"
)
Download-FirstOk -Urls $smythUrls -OutFile $smythOut
Normalize-Utf8Lf -Path $smythOut

# ---- AGLDT (optional; CC BY-SA 3.0) ---------------------------------------
if ($IncludeAGLDT) {
  $zipOut = Join-Path $agldt "treebank_data.zip"
  $agldtZipUrls = @(
    "https://github.com/PerseusDL/treebank_data/archive/refs/heads/master.zip",
    "https://github.com/PerseusDL/treebank_data/zipball/master"
  )
  Download-FirstOk -Urls $agldtZipUrls -OutFile $zipOut
  Write-Host "Expanding AGLDT ZIP ..."
  $dest = Join-Path $agldt "treebank_data"
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  Expand-Archive -Path $zipOut -DestinationPath $agldt -Force
  # normalize folder name
  $first = Get-ChildItem -Directory $agldt | Where-Object { $_.Name -match 'treebank_data' }
  if ($first -and ($first.FullName -ne $dest)) { Move-Item -Force $first.FullName $dest }
}

# ---- minimal vendor README / notices --------------------------------------
$vendorReadme = @"
This directory contains third-party data under original licenses.
- Perseus canonical Greek literature (Homer Iliad TEI, CC BY-SA).
- LSJ TEI from PerseusDL/lexica (CC BY-SA).
- Smyth (Alpheios HTML; XML provided by Perseus; page notes CC BY-NC-SA).
- AGLDT treebank (if present): CC BY-SA 3.0.

See docs/licensing-matrix.md for details and attributions.
"@
$readmePath = Join-Path $vendor "README.vendor.txt"
$vendorReadme | Out-File -FilePath $readmePath -Encoding UTF8 -Force

Write-Host "Done. Files written under data/vendor. You can now run:"
Write-Host "  uvicorn app.main:app --reload"
Write-Host "  python scripts/ingest_iliad_sample.py"
