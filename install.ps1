# selrai-mobile-kit installer (Windows PowerShell 7+)
# Idempotent. Safe to re-run. No destructive operations.

$ErrorActionPreference = "Stop"

$KitName    = "selrai-mobile-kit"
$KitVersion = "0.2.0-phase-0.2"
$RepoUrl    = "https://github.com/selrai-company/selrai-mobile-kit"

# Hard-pinned Expo SDK. Per Gian's confirmed decision 2026-05-18.
# Pinned to 55.0.24: latest stable on npm registry as of 2026-05-18.
# Source: registry.npmjs.org/expo (dist-tag latest -> 55.0.24, sdk-55 -> 55.0.24).
# Canonical SDK 55 template deps (expo-template-blank-typescript@sdk-55):
#   expo ~55.0.24, react 19.2.0, react-native 0.83.6, expo-status-bar ~55.0.6.
# Update only when Phase 0.3+ smoke tests pass on a new SDK.
$ExpoSdkPin = "55.0.24"

$ClaudeDir   = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $HOME ".claude" }
$SkillsDir   = Join-Path $ClaudeDir "skills"
$SettingsFile = Join-Path $ClaudeDir "settings.json"

function Log    { param($Msg) Write-Host "[selrai-mobile-kit] $Msg" }
function Fail   { param($Msg) Write-Host "[selrai-mobile-kit] ERROR: $Msg" -ForegroundColor Red; exit 1 }

Log "Phase 0.2 install. v$KitVersion."

# --- 1. Readiness check (Phase 0.2 expands into a Claude Code skill) ---

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Fail "Node.js not found. Install Node 20+ from https://nodejs.org and re-run." }
if (-not (Get-Command bun  -ErrorAction SilentlyContinue)) { Fail "Bun not found. Install from https://bun.sh and re-run." }

$NodeMajor = ([int]((node -v) -replace '^v(\d+).*', '$1'))
if ($NodeMajor -lt 20) { Fail "Node 20+ required. Found $(node -v)." }

Log "Tooling check passed (node $(node -v), bun $(bun -v))."

# --- 2. Anthropic-drift check (per-install, PREMORTEM #1 mitigation) ---

$KitStateDir  = Join-Path $ClaudeDir "selrai-mobile-kit"
$ManifestPath = Join-Path $KitStateDir "install-manifest.json"
if (-not (Test-Path $KitStateDir)) { New-Item -ItemType Directory -Path $KitStateDir -Force | Out-Null }

if (-not (Test-Path $ManifestPath)) {
  # First install: write baseline manifest.
  $Manifest = [ordered]@{
    kit                       = $KitName
    kit_version               = $KitVersion
    expo_sdk_pin              = $ExpoSdkPin
    installed_at              = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    anthropic_expo_plugin_url = "https://claude.com/plugins/expo"
    drift_check_cadence       = "per-install"
  }
  $Manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $ManifestPath -Encoding utf8
} else {
  # Subsequent installs: update mutable fields, preserve drift-check fields.
  try {
    $Existing = Get-Content $ManifestPath -Raw | ConvertFrom-Json -AsHashtable
    $Existing["kit_version"] = $KitVersion
    $Existing["expo_sdk_pin"] = $ExpoSdkPin
    $Existing["installed_at"] = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $Existing | ConvertTo-Json -Depth 10 | Out-File -FilePath $ManifestPath -Encoding utf8
  } catch {
    Log "Manifest refresh failed. Using existing manifest."
  }
}
Log "Install manifest at $ManifestPath."

# Run drift check (PowerShell implementation of tools/anthropic-drift-check.sh logic).
# Exit code 2 = drift detected. Treated as warning-only, never aborts install.
$TargetUrl = "https://claude.com/plugins/expo"
$DriftFired = $false
$CurrentHash = $null
$VersionStr  = $null

Log "Checking Anthropic expo plugin for changes..."

try {
  $Response = Invoke-WebRequest -Uri $TargetUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
  $Body = $Response.Content

  # Extract og:description
  $DescRaw = [regex]::Match($Body, 'property="og:description"[^>]*content="([^"]*)"').Groups[1].Value
  if (-not $DescRaw) {
    $DescRaw = [regex]::Match($Body, 'name="description"[^>]*content="([^"]*)"').Groups[1].Value
  }

  if ($DescRaw) {
    # Normalize whitespace
    $DescNorm = ($DescRaw -replace '\s+', ' ').Trim()

    # Compute SHA-256 hash via .NET
    $Bytes  = [System.Text.Encoding]::UTF8.GetBytes($DescNorm)
    $HashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Bytes)
    $CurrentHash = ($HashBytes | ForEach-Object { $_.ToString('x2') }) -join ''

    # Keyword check: terms whose presence (new since last install) signals overlap
    $Keywords = @("template","starter","wizard","onboard","non-technical","scan","QR","Expo Go","phone preview")

    # Load previous hash
    $PrevHash = $null
    try {
      $ManObj = Get-Content $ManifestPath -Raw | ConvertFrom-Json
      $PrevHash = $ManObj.anthropic_expo_plugin_description_hash
    } catch {}

    $ChangedTerms = @()
    if ($PrevHash -and ($PrevHash -ne $CurrentHash)) {
      $DriftFired = $true
      foreach ($kw in $Keywords) {
        if ($DescNorm -match [regex]::Escape($kw)) { $ChangedTerms += $kw }
      }
    }

    # Version field check
    $VersionMatch = [regex]::Match($Body, '"version"\s*:\s*"([^"]+)"')
    if ($VersionMatch.Success) { $VersionStr = $VersionMatch.Groups[1].Value }
    try {
      $ManObj2 = Get-Content $ManifestPath -Raw | ConvertFrom-Json
      $PrevVersion = $ManObj2.anthropic_expo_plugin_version
      if ($VersionStr -and $PrevVersion -and ($VersionStr -ne $PrevVersion)) { $DriftFired = $true }
    } catch {}

  } else {
    Log "Could not extract plugin description. Skipping drift comparison."
  }

} catch [System.Net.WebException] {
  $StatusCode = [int]$_.Exception.Response.StatusCode
  if ($StatusCode -eq 404) {
    $DriftFired = $true
    $CurrentHash = "404-page-not-found"
    Write-Host ""
    Write-Host "[selrai-mobile-kit] DRIFT DETECTED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The official Anthropic expo plugin page returned 404 (removed or renamed)."
    Write-Host ""
    Write-Host "Action required: Run /mobile-readiness-check and review docs/anthropic-overlap.md before scaffolding."
    Write-Host "File a note at: https://github.com/selrai-company/selrai-mobile-kit/issues"
    Write-Host ""
  } else {
    Log "Network error (HTTP $StatusCode). Skipping drift check."
  }
} catch {
  Log "Network unreachable or request failed. Skipping drift check."
}

if ($DriftFired -and $CurrentHash -ne "404-page-not-found") {
  $PrevHashDisplay = try { (Get-Content $ManifestPath -Raw | ConvertFrom-Json).anthropic_expo_plugin_description_hash } catch { "none" }
  $TermsDisplay = if ($ChangedTerms.Count -gt 0) { $ChangedTerms -join ", " } else { "none" }
  Write-Host ""
  Write-Host "[selrai-mobile-kit] DRIFT DETECTED" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "The official Anthropic expo plugin description changed since your last install."
  Write-Host ""
  Write-Host "Previous description hash: $PrevHashDisplay"
  Write-Host "Current description hash:  $CurrentHash"
  Write-Host "Changed terms detected:     $TermsDisplay"
  Write-Host ""
  Write-Host "Action required: Run /mobile-readiness-check and review docs/anthropic-overlap.md before scaffolding a new app."
  Write-Host "File a note at: https://github.com/selrai-company/selrai-mobile-kit/issues"
  Write-Host ""
  Log "Drift warning noted. Continuing install."
} elseif (-not $DriftFired -and $CurrentHash) {
  Log "No drift detected in Anthropic expo plugin."
}

# Update manifest with current drift-check state.
if ($CurrentHash) {
  try {
    $ManUpd = Get-Content $ManifestPath -Raw | ConvertFrom-Json -AsHashtable
    $ManUpd["anthropic_expo_plugin_description_hash"] = $CurrentHash
    $ManUpd["anthropic_expo_plugin_version"]          = $VersionStr
    $ManUpd["drift_check_last_run"]                   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $ManUpd["drift_alarm_fired"]                      = $DriftFired
    $ManUpd | ConvertTo-Json -Depth 10 | Out-File -FilePath $ManifestPath -Encoding utf8
  } catch {
    Log "Manifest drift-field update failed. Original untouched."
  }
}

# --- 3. Install skills (copy from kit repo, overwrite stubs) ---

if (-not (Test-Path $SkillsDir)) { New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null }

$KitSkillsDir = Join-Path $PSScriptRoot "skills"
if (Test-Path $KitSkillsDir) {
  Copy-Item -Recurse -Force (Join-Path $KitSkillsDir "*") $SkillsDir
  Log "Skills copied from $KitSkillsDir to $SkillsDir."
} else {
  Log "Kit skills directory not found at $KitSkillsDir. Skills not installed."
}

# Soft-warn if tool-output-fencing skill is absent (CONFIRM-002 security mitigation).
$FencingSkill = Join-Path $SkillsDir "tool-output-fencing.md"
if (-not (Test-Path $FencingSkill)) {
  Log "NOTE: tool-output-fencing skill not found at $FencingSkill."
  Log "      This skill guards against indirect prompt injection on template ingestion paths."
  Log "      Install it from the selrai-internal-kit or claude-workshop-kit before scaffolding."
  Log "      Install is not blocked. This is a security hardening recommendation."
}

# --- 4. settings.json merge (idempotent, additive, native PS) ---

if (-not (Test-Path $SettingsFile)) {
  '{}' | Out-File -FilePath $SettingsFile -Encoding utf8
  Log "Created $SettingsFile."
}

try {
  $Settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json -AsHashtable
} catch {
  Fail "Could not parse $SettingsFile as JSON. Original file untouched."
}

$Settings["selrai_mobile_kit"] = [ordered]@{
  version          = $KitVersion
  egress_allowlist = @(
    "registry.npmjs.org",
    "cdn.expo.dev",
    "u.expo.dev",
    "api.expo.dev",
    "exp.host"
  )
}
$Settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsFile -Encoding utf8
Log "Merged selrai_mobile_kit block into $SettingsFile."

# --- 5. Next steps ---

Write-Host ""
Write-Host "[selrai-mobile-kit] Phase 0.2 install complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Open Claude Code in any project directory."
Write-Host "  2. Paste the contents of SETUP-PROMPT.md into Claude Code."
Write-Host "  3. The kit walks you the rest of the way."
Write-Host ""
Write-Host "Track: $RepoUrl"
Write-Host ""
