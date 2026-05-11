# Research Copilot installer (Windows / PowerShell)
#
# Usage:
#   irm https://raw.githubusercontent.com/DIR-LAB/Research-Pilot/main/install.ps1 | iex
#
# Downloads the latest unsigned NSIS installer (.exe) from GitHub Releases
# and runs it. SmartScreen will warn ("Unrecognized app") because the build is
# unsigned — click "More info" → "Run anyway" to proceed.

$ErrorActionPreference = 'Stop'

$Repo      = 'DIR-LAB/Research-Pilot'
$ApiLatest = "https://api.github.com/repos/$Repo/releases/latest"
$AssetRx   = '\.exe$'

function Write-Info($msg) { Write-Host "  $msg" }
function Write-Ok($msg)   { Write-Host "  $msg" -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Err2($msg) { Write-Host "  $msg" -ForegroundColor Red }

Write-Host "Research Copilot installer" -ForegroundColor Cyan
Write-Info "OS:   Windows"
Write-Info "Arch: $env:PROCESSOR_ARCHITECTURE"

Write-Host "`nResolving latest release asset..." -ForegroundColor Cyan
try {
  $headers = @{ 'User-Agent' = 'research-copilot-installer' }
  $release = Invoke-RestMethod -Uri $ApiLatest -Headers $headers
} catch {
  Write-Err2 "failed to query GitHub API: $_"
  exit 1
}

$asset = $release.assets | Where-Object { $_.name -match $AssetRx } | Select-Object -First 1
if (-not $asset) {
  Write-Err2 "no .exe asset found in latest release"
  Write-Err2 "check https://github.com/$Repo/releases/latest"
  exit 1
}

Write-Ok "found: $($asset.browser_download_url)"

$tmp = Join-Path $env:TEMP "research-copilot-$(Get-Random).exe"
Write-Host "`nDownloading..." -ForegroundColor Cyan
try {
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp -UseBasicParsing
  Write-Ok "saved to $tmp"
} catch {
  Write-Err2 "download failed: $_"
  exit 1
}

Write-Host "`nLaunching installer..." -ForegroundColor Cyan
Write-Warn2 "Windows SmartScreen may show 'Unrecognized app' — this is expected for unsigned builds."
Write-Warn2 "Click 'More info' -> 'Run anyway' to proceed."

try {
  Start-Process -FilePath $tmp -Wait
  Write-Ok "installer exited"
} catch {
  Write-Err2 "failed to launch installer: $_"
  exit 1
}

Write-Host "`nDone." -ForegroundColor Green
Write-Info "Find 'Research Copilot' in the Start menu."
