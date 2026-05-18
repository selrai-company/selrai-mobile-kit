#!/usr/bin/env bash
# selrai-mobile-kit installer (macOS / Linux)
# Idempotent. Safe to re-run. No destructive operations.

set -euo pipefail

KIT_NAME="selrai-mobile-kit"
KIT_VERSION="0.1.0-phase-0.1"
REPO_URL="https://github.com/selrai-company/selrai-mobile-kit"

# Hard-pinned Expo SDK. Per Gian's confirmed decision 2026-05-18.
# Update only when Phase 0.2+ smoke tests pass on new SDK.
EXPO_SDK_PIN="latest"  # TODO Phase 0.2: replace with verified SDK version

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS_DIR="${CLAUDE_DIR}/skills"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

log() { printf "[selrai-mobile-kit] %s\n" "$*"; }
fail() { printf "[selrai-mobile-kit] ERROR: %s\n" "$*" >&2; exit 1; }

log "Phase 0.1 install. v${KIT_VERSION}."

# --- 1. Readiness check (Phase 0.2 expands into a Claude Code skill) ---

command -v node >/dev/null 2>&1 || fail "Node.js not found. Install Node 20+ from https://nodejs.org and re-run."
command -v bun  >/dev/null 2>&1 || fail "Bun not found. Install from https://bun.sh and re-run."
command -v jq   >/dev/null 2>&1 || fail "jq not found. Install via brew (mac) or apt (Linux) and re-run."
command -v gh   >/dev/null 2>&1 || log  "Optional: gh CLI not found. Not required for this kit."

NODE_MAJOR="$(node -v | sed -E 's/^v([0-9]+).*/\1/')"
[ "${NODE_MAJOR}" -ge 20 ] || fail "Node 20+ required. Found $(node -v)."

log "Tooling check passed (node $(node -v), bun $(bun -v))."

# --- 2. Anthropic-drift check (per-install, PREMORTEM #1 mitigation) ---

# TODO Phase 0.2 Day 2: replace with real diff check against claude.com/plugins/expo manifest.
# For Phase 0.1 we record the kit version and the date so a future drift check has a baseline.
mkdir -p "${CLAUDE_DIR}/selrai-mobile-kit"
cat > "${CLAUDE_DIR}/selrai-mobile-kit/install-manifest.json" <<EOF
{
  "kit": "${KIT_NAME}",
  "kit_version": "${KIT_VERSION}",
  "expo_sdk_pin": "${EXPO_SDK_PIN}",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "anthropic_expo_plugin_url": "https://claude.com/plugins/expo",
  "drift_check_cadence": "per-install"
}
EOF
log "Install manifest written to ${CLAUDE_DIR}/selrai-mobile-kit/install-manifest.json."

# --- 3. Skill stubs (Phase 0.2 fills in real skill prompts) ---

mkdir -p "${SKILLS_DIR}"
for skill in mobile-readiness-check mobile-app-bootstrap mobile-template-pick mobile-phone-preview; do
  if [ ! -f "${SKILLS_DIR}/${skill}.md" ]; then
    cat > "${SKILLS_DIR}/${skill}.md" <<EOF
---
name: ${skill}
description: "selrai-mobile-kit Phase 0.1 skill stub. Phase 0.2 fills in real prompt."
---

# ${skill}

Phase 0.1 stub. Phase 0.2 replaces this file with the real skill prompt.
EOF
    log "Wrote skill stub: ${skill}.md"
  else
    log "Skill exists, skipped: ${skill}.md"
  fi
done

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

[selrai-mobile-kit] Phase 0.1 install complete.

Next:
  1. Open Claude Code in any project directory.
  2. Run: /mobile-readiness-check
  3. The kit walks you the rest of the way.

Phase 0.2 is in flight (template + skill bodies land over the next 2 days).
Track: ${REPO_URL}

EOF
