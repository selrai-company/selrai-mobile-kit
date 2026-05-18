#!/usr/bin/env bash
# anthropic-drift-check.sh
# selrai-mobile-kit -- per-install drift detection for the Anthropic expo plugin.
# Per Section 5 of docs/anthropic-overlap.md (2026-05-18 spec).
#
# Exit codes:
#   0  -- no drift detected, or network failure (non-blocking)
#   2  -- drift detected (installer treats as warning-only, not abort)
#
# Dependencies: curl, sha256sum (or shasum -a 256 on macOS), jq.
# If any dependency is missing, exits 0 with a warning (never blocks install).
#
# Usage: bash tools/anthropic-drift-check.sh
# Called by install.sh section 2 after manifest is written.

set -uo pipefail

MANIFEST_DIR="${CLAUDE_DIR:-$HOME/.claude}/selrai-mobile-kit"
MANIFEST_FILE="${MANIFEST_DIR}/install-manifest.json"
TARGET_URL="https://claude.com/plugins/expo"
FETCH_TIMEOUT=10

# Keyword list: presence of any new term triggers a drift alarm.
KEYWORD_TRIGGERS="template starter wizard onboard non-technical scan QR Expo Go phone preview"

# ---- helper: check dependencies ----
_has() { command -v "$1" >/dev/null 2>&1; }

warn() { printf "[selrai-mobile-kit] drift-check warning: %s\n" "$*" >&2; }
note() { printf "[selrai-mobile-kit] %s\n" "$*"; }

if ! _has curl; then
  warn "curl not found. Skipping drift check."
  exit 0
fi

if ! _has jq; then
  warn "jq not found. Skipping drift check."
  exit 0
fi

# Detect sha256sum or shasum (macOS ships shasum, not sha256sum)
if _has sha256sum; then
  _sha256() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }
elif _has shasum; then
  _sha256() { printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; }
else
  warn "sha256sum / shasum not found. Skipping drift check."
  exit 0
fi

# ---- fetch the plugin page ----
note "Checking Anthropic expo plugin for changes..."

HTTP_BODY="$(curl -sSL --max-time "${FETCH_TIMEOUT}" "${TARGET_URL}" 2>/dev/null)" || {
  warn "Network unreachable or request timed out. Skipping drift check."
  exit 0
}

HTTP_STATUS="$(curl -sSo /dev/null -w "%{http_code}" --max-time "${FETCH_TIMEOUT}" "${TARGET_URL}" 2>/dev/null)" || HTTP_STATUS="000"

# ---- handle 404 (plugin removed or renamed) ----
if [ "${HTTP_STATUS}" = "404" ]; then
  PREV_HASH="$(jq -r '.anthropic_expo_plugin_description_hash // "none"' "${MANIFEST_FILE}" 2>/dev/null || echo "none")"
  CURRENT_HASH="404-page-not-found"
  printf "\n[selrai-mobile-kit] DRIFT DETECTED\n\n"
  printf "The official Anthropic expo plugin page returned 404 (removed or renamed).\n\n"
  printf "Previous description hash: %s\n" "${PREV_HASH}"
  printf "Current description hash:  %s\n" "${CURRENT_HASH}"
  printf "Changed terms detected:     plugin page missing\n\n"
  printf "Action required: Run /mobile-readiness-check and review the Phase 0.2 Day 1 audit doc at docs/anthropic-overlap.md before scaffolding a new app. If Anthropic now ships a feature this kit duplicates, the relevant skill will be deprecated in the next kit release.\n\n"
  printf "File a note at: https://github.com/selrai-company/selrai-mobile-kit/issues\n\n"
  # Update manifest with 404 state
  if [ -f "${MANIFEST_FILE}" ]; then
    TMP="$(mktemp)"
    jq --arg h "${CURRENT_HASH}" \
       --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.anthropic_expo_plugin_description_hash = $h
      | .anthropic_expo_plugin_version = null
      | .drift_check_last_run = $ts
      | .drift_alarm_fired = true' \
      "${MANIFEST_FILE}" > "${TMP}" && mv "${TMP}" "${MANIFEST_FILE}"
  fi
  exit 2
fi

# ---- non-200 responses other than 404 ----
if [ "${HTTP_STATUS}" != "200" ] && [ "${HTTP_STATUS}" != "301" ] && [ "${HTTP_STATUS}" != "302" ]; then
  warn "Plugin page returned HTTP ${HTTP_STATUS}. Skipping drift check."
  exit 0
fi

# ---- extract description block ----
# Strategy: pull the meta description tag, then the first <p> block in the main content area.
# Normalize whitespace for stable hashing.

# Try og:description meta tag first (most stable cross-render)
DESC_RAW="$(printf '%s' "${HTTP_BODY}" | grep -oP '(?<=<meta[^>]*property="og:description"[^>]*content=")[^"]*' 2>/dev/null || true)"

# Fallback: meta name="description"
if [ -z "${DESC_RAW}" ]; then
  DESC_RAW="$(printf '%s' "${HTTP_BODY}" | grep -oP '(?<=<meta[^>]*name="description"[^>]*content=")[^"]*' 2>/dev/null || true)"
fi

# Fallback: grab visible text between <p> tags in the first 8KB of body
if [ -z "${DESC_RAW}" ]; then
  DESC_RAW="$(printf '%s' "${HTTP_BODY}" | head -c 8192 | sed -E 's/<[^>]+>//g' | grep -v '^[[:space:]]*$' | head -5 | tr '\n' ' ' || true)"
fi

# Normalize whitespace
DESC_NORMALIZED="$(printf '%s' "${DESC_RAW}" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')"

if [ -z "${DESC_NORMALIZED}" ]; then
  warn "Could not extract plugin description. Skipping drift check."
  exit 0
fi

CURRENT_HASH="$(_sha256 "${DESC_NORMALIZED}")"

# ---- load previous hash from manifest ----
PREV_HASH=""
if [ -f "${MANIFEST_FILE}" ]; then
  PREV_HASH="$(jq -r '.anthropic_expo_plugin_description_hash // ""' "${MANIFEST_FILE}" 2>/dev/null || echo "")"
fi

# ---- keyword check (highest-signal) ----
CHANGED_TERMS=""
for kw in ${KEYWORD_TRIGGERS}; do
  # Check if keyword appears in current description but not in recorded previous state
  if printf '%s' "${DESC_NORMALIZED}" | grep -qi "${kw}"; then
    # Check if it was absent in prior baseline (we track keywords separately via the hash comparison)
    # If prev_hash was empty (first install), we have no baseline for keyword diff, skip keyword alarm.
    if [ -n "${PREV_HASH}" ] && [ "${PREV_HASH}" != "${CURRENT_HASH}" ]; then
      CHANGED_TERMS="${CHANGED_TERMS} ${kw}"
    fi
  fi
done

DRIFT_FIRED=false

# ---- compare hashes ----
if [ -n "${PREV_HASH}" ] && [ "${PREV_HASH}" != "${CURRENT_HASH}" ]; then
  DRIFT_FIRED=true
fi

# ---- extract version / updated-at from page ----
VERSION_STR="$(printf '%s' "${HTTP_BODY}" | grep -oP '(?<="version":")[^"]+' | head -1 2>/dev/null || echo "")"
PREV_VERSION="$(jq -r '.anthropic_expo_plugin_version // ""' "${MANIFEST_FILE}" 2>/dev/null || echo "")"

if [ -n "${VERSION_STR}" ] && [ -n "${PREV_VERSION}" ] && [ "${VERSION_STR}" != "${PREV_VERSION}" ]; then
  DRIFT_FIRED=true
fi

# ---- emit drift alarm ----
if [ "${DRIFT_FIRED}" = "true" ]; then
  TERMS_DISPLAY="${CHANGED_TERMS:-none}"
  printf "\n[selrai-mobile-kit] DRIFT DETECTED\n\n"
  printf "The official Anthropic expo plugin description changed since your last install.\n\n"
  printf "Previous description hash: %s\n" "${PREV_HASH}"
  printf "Current description hash:  %s\n" "${CURRENT_HASH}"
  printf "Changed terms detected:     %s\n\n" "${TERMS_DISPLAY}"
  printf "Action required: Run /mobile-readiness-check and review the Phase 0.2 Day 1 audit doc at docs/anthropic-overlap.md before scaffolding a new app. If Anthropic now ships a feature this kit duplicates, the relevant skill will be deprecated in the next kit release.\n\n"
  printf "File a note at: https://github.com/selrai-company/selrai-mobile-kit/issues\n\n"
  DRIFT_JSON_BOOL="true"
else
  note "No drift detected in Anthropic expo plugin."
  DRIFT_JSON_BOOL="false"
fi

# ---- update manifest (always, drift or not) ----
if [ -f "${MANIFEST_FILE}" ]; then
  TMP="$(mktemp)"
  jq --arg h "${CURRENT_HASH}" \
     --arg v "${VERSION_STR}" \
     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --argjson fired "${DRIFT_JSON_BOOL}" \
     '.anthropic_expo_plugin_description_hash = $h
    | .anthropic_expo_plugin_version = (if $v == "" then null else $v end)
    | .drift_check_last_run = $ts
    | .drift_alarm_fired = $fired' \
    "${MANIFEST_FILE}" > "${TMP}" && mv "${TMP}" "${MANIFEST_FILE}" \
  || warn "Manifest update failed. Original untouched."
fi

# Exit 2 if drift fired, 0 otherwise.
[ "${DRIFT_FIRED}" = "true" ] && exit 2 || exit 0
