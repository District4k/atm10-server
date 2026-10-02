# Apply the latest client-overlay.zip onto an ATM10 Prism/CurseForge instance (Windows).
# Usage:
#   powershell -ExecutionPolicy Bypass -File update-client.ps1
#   powershell -ExecutionPolicy Bypass -File update-client.ps1 "C:\path\to\instance"
# Prism pre-launch:
#   powershell -ExecutionPolicy Bypass -File "C:\path\to\update-client.ps1" "$env:INST_DIR"

param(
  [string]$Instance = $env:INST_DIR
)

$ErrorActionPreference = "Stop"
$Repo = if ($env:ATM10_FORK_REPO) { $env:ATM10_FORK_REPO } else { "District4k/atm10-server" }

if (-not $Instance) {
  Write-Host @"
Usage:
  .\update-client.ps1 "C:\path\to\ATM10-instance"

Prism pre-launch command:
  powershell -ExecutionPolicy Bypass -File `"C:\Games\atm10-update\update-client.ps1`" `"$env:INST_DIR`"
"@
  exit 1
}

if (-not (Test-Path -LiteralPath $Instance)) {
  throw "Instance folder does not exist: $Instance"
}

$api = "https://api.github.com/repos/$Repo/releases/latest"
Write-Host "[client] fetching $api"
$release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "atm10-update-client" }
$asset = $release.assets | Where-Object { $_.name -eq "client-overlay.zip" } | Select-Object -First 1
if (-not $asset) {
  throw "Latest release has no client-overlay.zip"
}

$tmp = Join-Path $env:TEMP ("atm10-overlay-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
$zip = Join-Path $tmp "client-overlay.zip"

Write-Host "[client] downloading $($release.tag_name) -> client-overlay.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing

New-Item -ItemType Directory -Force -Path (Join-Path $Instance "mods") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Instance "config") | Out-Null
Expand-Archive -LiteralPath $zip -DestinationPath $Instance -Force
Remove-Item -Recurse -Force $tmp

$glitch = Join-Path $Instance "mods\GlitchCore-neoforge-1.21.1-2.1.0.2.jar"
if (-not (Test-Path -LiteralPath $glitch)) {
  throw @"
[client] overlay $($release.tag_name) did not install GlitchCore.
Without it the server kicks with glitchcore:sync_config missing.
Re-download update-client.ps1 and try again, or tell the host the GitHub client-overlay.zip is broken.
"@
}

Write-Host "[client] OK - overlay $($release.tag_name) applied to $Instance (GlitchCore present)"
Write-Host "[client] Use official ATM10 8.2 / NeoForge 21.1.251 (same as the server), then join."
