#!/usr/bin/env bash
# tests/piped_exec_smoke.sh
#
# Simulates piped-exec invocation of install.sh (the common `curl ... | bash`
# distribution path that workshop attendees use). Verifies the kit's piped-exec
# detection + git-clone fallback + skill copy all complete cleanly.
#
# Closes CONFIRM-005 regression coverage.
#
# Requires: node 20+, bun, jq, git, network access to github.com.
# Skips with exit 0 if any prereq is missing.

set -euo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SMOKE_HOME="$(mktemp -d 2>/dev/null || mktemp -d -t piped-smoke)"
trap 'rm -rf "${SMOKE_HOME}"' EXIT

PASSED=0
TOTAL=0

assert() {
  local label="$1"
  local cond="$2"
  TOTAL=$((TOTAL + 1))
  if eval "${cond}"; then
    printf "PASS  %s\n" "${label}"
    PASSED=$((PASSED + 1))
  else
    printf "FAIL  %s\n" "${label}"
  fi
}

# --- Prereq probe ---
for cmd in node bun jq git; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    printf "SKIP  (prereq missing: %s)\n" "${cmd}"
    exit 0
  fi
done

# --- Run install.sh through stdin (simulates `curl ... | bash`) ---
# Run from a clean cwd (NOT the kit root) so that dirname "." does not
# coincidentally resolve to a dir with the kit layout. Real users running
# `curl ... | bash` from ~ are in a cwd without skills/ + tools/ adjacent.
INSTALL_LOG="${SMOKE_HOME}/install.log"
CLAUDE_DIR_T="${SMOKE_HOME}/.claude"
mkdir -p "${CLAUDE_DIR_T}"
mkdir -p "${SMOKE_HOME}/cwd"

set +e
( cd "${SMOKE_HOME}/cwd" && cat "${KIT_ROOT}/install.sh" | CLAUDE_DIR="${CLAUDE_DIR_T}" bash ) > "${INSTALL_LOG}" 2>&1
INSTALL_EXIT=$?
set -e

if [ "${INSTALL_EXIT}" -ne 0 ]; then
  printf "FAIL  install.sh piped exit code (%d)\n" "${INSTALL_EXIT}"
  printf "      last 30 log lines:\n"
  tail -30 "${INSTALL_LOG}" | sed 's/^/        /'
  printf "passed=0/1 (early abort)\n"
  exit 1
fi

# --- Assertions ---
assert "piped-exec mode was detected and logged" \
  "grep -q 'Piped-exec mode detected' '${INSTALL_LOG}'"

assert "kit was cloned to a temp dir (clone log line present)" \
  "grep -q 'Kit cloned to' '${INSTALL_LOG}'"

assert "drift-check ran from the cloned dir (no 'Skipping' fallback)" \
  "! grep -q 'Drift check script not found' '${INSTALL_LOG}'"

assert "drift-check produced a hash (manifest field set)" \
  "[ -f '${CLAUDE_DIR_T}/selrai-mobile-kit/install-manifest.json' ] && jq -e '.anthropic_expo_plugin_description_hash != null' '${CLAUDE_DIR_T}/selrai-mobile-kit/install-manifest.json' >/dev/null"

assert "all 4 skills installed (mobile-readiness-check)" \
  "[ -f '${CLAUDE_DIR_T}/skills/mobile-readiness-check.md' ]"
assert "all 4 skills installed (mobile-app-bootstrap)" \
  "[ -f '${CLAUDE_DIR_T}/skills/mobile-app-bootstrap.md' ]"
assert "all 4 skills installed (mobile-template-pick)" \
  "[ -f '${CLAUDE_DIR_T}/skills/mobile-template-pick.md' ]"
assert "all 4 skills installed (mobile-phone-preview)" \
  "[ -f '${CLAUDE_DIR_T}/skills/mobile-phone-preview.md' ]"

assert "settings.json has selrai_mobile_kit block" \
  "jq -e '.selrai_mobile_kit.egress_allowlist | length >= 5' '${CLAUDE_DIR_T}/settings.json' >/dev/null"

assert "tool-output-fencing soft-warn fired (expected on a fresh install)" \
  "grep -q 'tool-output-fencing skill not found' '${INSTALL_LOG}'"

assert "no fatal error lines in install output" \
  "! grep -q 'ERROR:' '${INSTALL_LOG}'"

# --- Idempotency: run again through the pipe, must stay green ---
set +e
( cd "${SMOKE_HOME}/cwd" && cat "${KIT_ROOT}/install.sh" | CLAUDE_DIR="${CLAUDE_DIR_T}" bash ) > "${SMOKE_HOME}/install-2.log" 2>&1
INSTALL2_EXIT=$?
set -e
assert "second piped install exits 0 (idempotent)" "[ ${INSTALL2_EXIT} -eq 0 ]"

assert "second install also detected piped-exec mode" \
  "grep -q 'Piped-exec mode detected' '${SMOKE_HOME}/install-2.log'"

# Note: temp-clone cleanup is covered by install.sh's EXIT trap. Verifying it
# externally is brittle (false-positives on unrelated tmp dirs), so we trust
# the trap and skip a cleanup assertion here.

printf "\npassed=%d/%d\n" "${PASSED}" "${TOTAL}"
if [ "${PASSED}" -eq "${TOTAL}" ]; then
  printf "RESULT: PASS\n"
  exit 0
else
  printf "RESULT: FAIL\n"
  exit 1
fi
