# selrai-mobile-kit installer (Windows PowerShell 7+)
# Idempotent. Safe to re-run. No destructive operations.

$ErrorActionPreference = "Stop"

$KitName    = "selrai-mobile-kit"
$KitVersion = "0.1.0-phase-0.1"
$RepoUrl    = "https://github.com/selrai-company/selrai-mobile-kit"

# Hard-pinned Expo SDK. Per Gian's confirmed decision 2026-05-18.
# Update only when Phase 0.2+ smoke tests pass on new SDK.
$ExpoSdkPin = "latest"  # TODO Phase 0.2: replace with verified SDK version

$ClaudeDir   = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $HOME ".claude" }
$SkillsDir   = Join-Path $ClaudeDir "skills"
$SettingsFile = Join-Path $ClaudeDir "settings.json"

function Log    { param($Msg) Write-Host "[selrai-mobile-kit] $Msg" }
function Fail   { param($Msg) Write-Host "[selrai-mobile-kit] ERROR: $Msg" -ForegroundColor Red; exit 1 }

Log "Phase 0.1 install. v$KitVersion."

# --- 1. Readiness check (Phase 0.2 expands into a Claude Code skill) ---

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Fail "Node.js not found. Install Node 20+ from https://nodejs.org and re-run." }
if (-not (Get-Command bun  -ErrorAction SilentlyContinue)) { Fail "Bun not found. Install from https://bun.sh and re-run." }

$NodeMajor = ([int]((node -v) -replace '^v(\d+).*', '$1'))
if ($NodeMajor -lt 20) { Fail "Node 20+ required. Found $(node -v)." }

Log "Tooling check passed (node $(node -v), bun $(bun -v))."

# --- 2. Anthropic-drift check (per-install, PREMORTEM #1 mitigation) ---

# TODO Phase 0.2 Day 2: replace with real diff check against claude.com/plugins/expo manifest.
$KitStateDir = Join-Path $ClaudeDir "selrai-mobile-kit"
if (-not (Test-Path $KitStateDir)) { New-Item -ItemType Directory -Path $KitStateDir -Force | Out-Null }

$Manifest = [ordered]@{
  kit                       = $KitName
  kit_version               = $KitVersion
  expo_sdk_pin              = $ExpoSdkPin
  installed_at              = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  anthropic_expo_plugin_url = "https://claude.com/plugins/expo"
  drift_check_cadence       = "per-install"
}
$ManifestPath = Join-Path $KitStateDir "install-manifest.json"
$Manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $ManifestPath -Encoding utf8
Log "Install manifest written to $ManifestPath."

# --- 3. Skill stubs (Phase 0.2 fills in real skill prompts) ---

if (-not (Test-Path $SkillsDir)) { New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null }

foreach ($skill in @("mobile-readiness-check", "mobile-app-bootstrap", "mobile-template-pick", "mobile-phone-preview")) {
  $SkillFile = Join-Path $SkillsDir "$skill.md"
  if (-not (Test-Path $SkillFile)) {
    $Body = @"
---
name: $skill
description: "selrai-mobile-kit Phase 0.1 skill stub. Phase 0.2 fills in real prompt."
---

# $skill

Phase 0.1 stub. Phase 0.2 replaces this file with the real skill prompt.
"@
    $Body | Out-File -FilePath $SkillFile -Encoding utf8
    Log "Wrote skill stub: $skill.md"
  } else {
    Log "Skill exists, skipped: $skill.md"
  }
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
Write-Host "[selrai-mobile-kit] Phase 0.1 install complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Open Claude Code in any project directory."
Write-Host "  2. Run: /mobile-readiness-check"
Write-Host "  3. The kit walks you the rest of the way."
Write-Host ""
Write-Host "Phase 0.2 is in flight (template + skill bodies land over the next 2 days)."
Write-Host "Track: $RepoUrl"
Write-Host ""
