# selrai-mobile-kit, uninstaller (Windows PowerShell 7+)
#
# Removes:
#   - 4 mobile-* skill files from ~/.claude/skills/
#   - ~/.claude/selrai-mobile-kit/ (manifest + drift state)
#   - .selrai_mobile_kit key from ~/.claude/settings.json (native PS JSON)
#
# Flags:
#   -Yes      non-interactive (no confirmation prompt)
#   -DryRun   print what would be removed, do not remove anything
#
# Idempotent. Safe to run when nothing is installed (exits 0).
# Exit codes: 0 success, 1 user cancel, 2 filesystem error.

param(
  [switch]$Yes,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ClaudeDir    = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $HOME ".claude" }
$SkillsDir    = Join-Path $ClaudeDir "skills"
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$KitStateDir  = Join-Path $ClaudeDir "selrai-mobile-kit"

$Skills = @(
  "mobile-readiness-check.md",
  "mobile-app-bootstrap.md",
  "mobile-template-pick.md",
  "mobile-phone-preview.md"
)

function Log-Bold  { param($Msg) Write-Host $Msg -ForegroundColor White }
function Log-Ok    { param($Msg) Write-Host "  ok   $Msg" -ForegroundColor Green }
function Log-Skip  { param($Msg) Write-Host "  skip $Msg" -ForegroundColor Yellow }
function Log-Plan  { param($Msg) Write-Host "  plan $Msg" -ForegroundColor Cyan }
function Log-Err   { param($Msg) Write-Host "  err  $Msg" -ForegroundColor Red }

Write-Host ""
Log-Bold "selrai-mobile-kit, uninstaller"
if ($DryRun) { Log-Bold "(dry-run, no changes)" }
Write-Host ""

# ---- count items present ----
$ItemCount = 0
foreach ($skill in $Skills) {
  if (Test-Path (Join-Path $SkillsDir $skill)) { $ItemCount++ }
}
if (Test-Path $KitStateDir) { $ItemCount++ }
if (Test-Path $SettingsFile) {
  try {
    $s = Get-Content $SettingsFile -Raw | ConvertFrom-Json -AsHashtable
    if ($s.ContainsKey("selrai_mobile_kit")) { $ItemCount++ }
  } catch {}
}

if ($ItemCount -eq 0) {
  Log-Bold "Nothing to remove (kit not installed)."
  Write-Host ""
  exit 0
}

# ---- confirmation prompt ----
if (-not $Yes -and -not $DryRun) {
  Write-Host "This will remove $ItemCount item(s) installed by selrai-mobile-kit."
  $reply = Read-Host "Continue? [y/N]"
  if ($reply -notmatch '^[Yy]') {
    Write-Host "Cancelled."
    exit 1
  }
  Write-Host ""
}

# ---- remove helpers ----
function Remove-File-Safe {
  param([string]$Target)
  if (-not (Test-Path $Target)) {
    Log-Skip "already removed: $Target"
    return
  }
  if ($DryRun) {
    Log-Plan "would remove file: $Target"
  } else {
    try {
      Remove-Item -Force $Target -ErrorAction Stop
      Log-Ok "removed: $Target"
    } catch {
      Log-Err "could not remove: $Target ($_)"
      exit 2
    }
  }
}

function Remove-Dir-Safe {
  param([string]$Target)
  if (-not (Test-Path $Target)) {
    Log-Skip "already removed: $Target"
    return
  }
  if ($DryRun) {
    Log-Plan "would remove dir: $Target"
  } else {
    try {
      Remove-Item -Recurse -Force $Target -ErrorAction Stop
      Log-Ok "removed dir: $Target"
    } catch {
      Log-Err "could not remove dir: $Target ($_)"
      exit 2
    }
  }
}

# ---- 1. Skills ----
Log-Bold "Skills:"
foreach ($skill in $Skills) {
  Remove-File-Safe (Join-Path $SkillsDir $skill)
}

# ---- 2. Kit state dir ----
Write-Host ""
Log-Bold "Kit state:"
Remove-Dir-Safe $KitStateDir

# ---- 3. settings.json surgery ----
Write-Host ""
Log-Bold "settings.json:"
if (-not (Test-Path $SettingsFile)) {
  Log-Skip "settings.json not found (nothing to patch)"
} else {
  try {
    $Settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json -AsHashtable
  } catch {
    Log-Err "Could not parse $SettingsFile as JSON. Manual removal required."
    exit 2
  }

  if (-not $Settings.ContainsKey("selrai_mobile_kit")) {
    Log-Skip "selrai_mobile_kit key already absent from settings.json"
  } elseif ($DryRun) {
    Log-Plan "would delete selrai_mobile_kit from $SettingsFile"
  } else {
    $Settings.Remove("selrai_mobile_kit")
    try {
      $Settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $SettingsFile -Encoding utf8 -ErrorAction Stop
      Log-Ok "removed selrai_mobile_kit key from $SettingsFile"
    } catch {
      Log-Err "Write failed -- $SettingsFile may be partially written. Check manually."
      exit 2
    }
  }
}

Write-Host ""
Log-Bold "Done."
Write-Host ""
