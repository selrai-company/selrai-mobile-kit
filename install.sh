#!/usr/bin/env bash
# selrai-mobile-kit installer (macOS / Linux)
# Idempotent. Safe to re-run. No destructive operations.

set -euo pipefail

KIT_NAME="selrai-mobile-kit"
KIT_VERSION="0.2.0-phase-0.2"
REPO_URL="https://github.com/selrai-company/selrai-mobile-kit"

# Hard-pinned Expo SDK. Per Gian's confirmed decision 2026-05-18 + Phase 0.2
# Day 3 smoke finding 2026-05-18: pin must match what the App Store / Play
# Store Expo Go currently supports, NOT what's `latest` on npm.
# Store Expo Go 54.0.8 supports SDK 54 only. Pinning to SDK 55 caused
# "Project is incompatible with this version of Expo Go" on first scan.
# Pinned to 54.0.34 (npm dist-tag sdk-54).
# Canonical SDK 54 template deps (expo-template-blank-typescript@sdk-54):
#   expo ~54.0.33, react 19.1.0, react-native 0.81.5, expo-status-bar ~3.0.9.
# Phase 0.3 reviews: bump when store Expo Go ships SDK 55 support AND
# the kit's smoke test re-passes on a real phone.
EXPO_SDK_PIN="54.0.34"

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS_DIR="${CLAUDE_DIR}/skills"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

log() { printf "[selrai-mobile-kit] %s\n" "$*"; }
fail() { printf "[selrai-mobile-kit] ERROR: %s\n" "$*" >&2; exit 1; }

log "Phase 0.2 install. v${KIT_VERSION}."

# --- 0. Detect piped-exec mode (run via curl ... | bash, process substitution, or stdin) ---
# In direct invocation, $0 is the script path and dirname "$0" resolves to a
# directory with the kit's skills/ and tools/ adjacent. When the installer is
# piped (e.g. `bash <(curl -sSL .../install.sh)` or `curl -sSL .../install.sh
# | bash`), $0 is empty / "bash" / "/dev/fd/N" and those adjacent dirs do not
# exist on the local filesystem. Closes CONFIRM-005.

# Resolve script directory only if $0 (or BASH_SOURCE[0]) is a real file.
# When piped (cat | bash, curl | bash, bash <(...)), $0 is "bash" / "" /
# /dev/fd/N and "-f $0" returns false. Falling back to dirname on a non-path
# string returns "." which silently resolves to cwd, masking piped mode.
SCRIPT_DIR=""
SCRIPT_SOURCE=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_SOURCE="${BASH_SOURCE[0]}"
elif [ -n "$0" ] && [ -f "$0" ]; then
  SCRIPT_SOURCE="$0"
fi
if [ -n "${SCRIPT_SOURCE}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_SOURCE}")" 2>/dev/null && pwd 2>/dev/null || echo "")"
fi

TEMP_CLONE=""

# Piped-exec if no resolvable script dir OR the dir is missing kit layout.
# Require BOTH skills/ AND tools/ to consider it a real kit checkout (reduces
# false-negative if cwd happens to contain a skills/ dir by coincidence).
if [ -z "${SCRIPT_DIR}" ] || [ ! -d "${SCRIPT_DIR}/skills" ] || [ ! -d "${SCRIPT_DIR}/tools" ]; then
  log "Piped-exec mode detected (no kit dir adjacent to script). Cloning kit to temp..."
  command -v git >/dev/null 2>&1 || fail "git not found. Required for piped install. Install git from https://git-scm.com then re-run."
  TEMP_CLONE="$(mktemp -d 2>/dev/null || mktemp -d -t selrai-mobile-kit)"
  if ! git clone --depth 1 "${REPO_URL}.git" "${TEMP_CLONE}" 2>&1 | tail -3; then
    rm -rf "${TEMP_CLONE}"
    fail "git clone of ${REPO_URL} failed. Check network access to github.com."
  fi
  SCRIPT_DIR="${TEMP_CLONE}"
  trap 'if [ -n "${TEMP_CLONE}" ] && [ -d "${TEMP_CLONE}" ]; then rm -rf "${TEMP_CLONE}"; fi' EXIT
  log "Kit cloned to ${TEMP_CLONE}. Will clean up on exit."
fi

# --- 1. Readiness check (Phase 0.2 expands into a Claude Code skill) ---

command -v node >/dev/null 2>&1 || fail "Node.js not found. Install Node 20+ from https://nodejs.org and re-run."
command -v bun  >/dev/null 2>&1 || fail "Bun not found. Install from https://bun.sh and re-run."
command -v jq   >/dev/null 2>&1 || fail "jq not found. Install via brew (mac) or apt (Linux) and re-run."
command -v gh   >/dev/null 2>&1 || log  "Optional: gh CLI not found. Not required for this kit."

NODE_MAJOR="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
[ "${NODE_MAJOR}" -ge 20 ] || fail "Node 20+ required. Found $(node -v)."

log "Tooling check passed (node $(node -v), bun $(bun -v))."

# --- 2. Anthropic-drift check (per-install, PREMORTEM #1 mitigation) ---

mkdir -p "${CLAUDE_DIR}/selrai-mobile-kit"
MANIFEST_FILE="${CLAUDE_DIR}/selrai-mobile-kit/install-manifest.json"

# Write / refresh the manifest baseline. jq merge preserves existing drift-check fields.
if [ ! -f "${MANIFEST_FILE}" ]; then
  cat > "${MANIFEST_FILE}" <<EOF
{
  "kit": "${KIT_NAME}",
  "kit_version": "${KIT_VERSION}",
  "expo_sdk_pin": "${EXPO_SDK_PIN}",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "anthropic_expo_plugin_url": "https://claude.com/plugins/expo",
  "drift_check_cadence": "per-install"
}
EOF
else
  TMP_MANIFEST="$(mktemp)"
  jq --arg v "${KIT_VERSION}" --arg p "${EXPO_SDK_PIN}" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.kit_version = $v | .expo_sdk_pin = $p | .installed_at = $ts' \
    "${MANIFEST_FILE}" > "${TMP_MANIFEST}" && mv "${TMP_MANIFEST}" "${MANIFEST_FILE}" \
  || log "Manifest refresh failed. Using existing manifest."
fi
log "Install manifest at ${MANIFEST_FILE}."

# Run drift check. Exit code 2 = drift detected (warning-only, never aborts install).
DRIFT_CHECK_SCRIPT="${SCRIPT_DIR}/tools/anthropic-drift-check.sh"
if [ -f "${DRIFT_CHECK_SCRIPT}" ]; then
  bash "${DRIFT_CHECK_SCRIPT}" || {
    DRIFT_EXIT=$?
    if [ "${DRIFT_EXIT}" -eq 2 ]; then
      log "Drift warning noted. Continuing install."
    else
      log "Drift check returned unexpected exit code ${DRIFT_EXIT}. Continuing install."
    fi
  }
else
  log "Drift check script not found at ${DRIFT_CHECK_SCRIPT}. Skipping."
fi

# --- 3. Install skills (copy from kit repo, overwrite stubs) ---

mkdir -p "${SKILLS_DIR}"
KIT_SKILLS_DIR="${SCRIPT_DIR}/skills"

if [ -d "${KIT_SKILLS_DIR}" ]; then
  cp -r "${KIT_SKILLS_DIR}"/. "${SKILLS_DIR}/"
  log "Skills copied from ${KIT_SKILLS_DIR} to ${SKILLS_DIR}."
else
  log "Kit skills directory not found at ${KIT_SKILLS_DIR}. Skills not installed."
fi

# Soft-warn if tool-output-fencing skill is absent (security mitigation for CONFIRM-002).
if [ ! -f "${SKILLS_DIR}/tool-output-fencing.md" ]; then
  log "NOTE: tool-output-fencing skill not found at ${SKILLS_DIR}/tool-output-fencing.md."
  log "      This skill guards against indirect prompt injection on template ingestion paths."
  log "      Install it from the selrai-internal-kit or claude-workshop-kit before scaffolding."
  log "      Install is not blocked. This is a security hardening recommendation."
fi

# --- 4. settings.json jq-merge (idempotent, additive) ---

if [ ! -f "${SETTINGS_FILE}" ]; then
  printf '{}\n' > "${SETTINGS_FILE}"
  log "Created ${SETTINGS_FILE}."
fi

# Egress allowlist baked in. Phase 0.2 verifies exact host list.
# Reject silently if jq merge fails (defensive, never corrupt user's settings).
TMP_SETTINGS="$(mktemp)"
jq '
  .selrai_mobile_kit = {
    "version": "'"${KIT_VERSION}"'",
    "egress_allowlist": [
      "registry.npmjs.org",
      "cdn.expo.dev",
      "u.expo.dev",
      "api.expo.dev",
      "exp.host"
    ]
  }
' "${SETTINGS_FILE}" > "${TMP_SETTINGS}" && mv "${TMP_SETTINGS}" "${SETTINGS_FILE}" \
  || fail "settings.json merge failed. Original file untouched."
log "Merged selrai_mobile_kit block into ${SETTINGS_FILE}."

# --- 5. Next steps ---

cat <<EOF

[selrai-mobile-kit] Phase 0.2 install complete.

Next:
  1. Open Claude Code in any project directory.
  2. Paste the contents of SETUP-PROMPT.md into Claude Code.
  3. The kit walks you the rest of the way.

Track: ${REPO_URL}

EOF
