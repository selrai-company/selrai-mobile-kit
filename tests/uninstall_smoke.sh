#!/usr/bin/env bash
#
# tests/uninstall_smoke.sh
#
# Smoke test for selrai-mobile-kit uninstall path.
#
# Sequence:
#   1. Install into a temp CLAUDE_DIR (simulates a fresh install).
#   2. Assert all artifacts are present.
#   3. Uninstall --yes into the same CLAUDE_DIR.
#   4. Assert all artifacts are removed.
#   5. Assert settings.json still exists and other keys are preserved.
#   6. Run uninstall --yes a second time (idempotency check, must exit 0).
#
# Print passed=N/N at the end.
#
# Requires: node 20+, bun, jq, git.
# Skips with exit 0 if any prereq is missing.

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SMOKE_HOME="$(mktemp -d 2>/dev/null || mktemp -d -t uninstall-smoke)"
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

# ---- Prereq probe ----
for cmd in node bun jq git; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    printf "SKIP  (prereq missing: %s)\n" "${cmd}"
    exit 0
  fi
done

CLAUDE_DIR_T="${SMOKE_HOME}/.claude"
SKILLS_DIR_T="${CLAUDE_DIR_T}/skills"
SETTINGS_T="${CLAUDE_DIR_T}/settings.json"
KIT_STATE_T="${CLAUDE_DIR_T}/selrai-mobile-kit"

mkdir -p "${CLAUDE_DIR_T}"
mkdir -p "${SMOKE_HOME}/cwd"

# -------- PHASE 1: install --------
INSTALL_LOG="${SMOKE_HOME}/install.log"

set +e
( cd "${SMOKE_HOME}/cwd" && cat "${KIT_ROOT}/install.sh" \
    | CLAUDE_DIR="${CLAUDE_DIR_T}" bash ) > "${INSTALL_LOG}" 2>&1
INSTALL_EXIT=$?
set -e

if [ "${INSTALL_EXIT}" -ne 0 ]; then
  printf "FAIL  install.sh exited %d (cannot test uninstall without a clean install)\n" "${INSTALL_EXIT}"
  printf "      last 30 lines:\n"
  tail -30 "${INSTALL_LOG}" | sed 's/^/        /'
  printf "\npassed=0/1 (install abort)\n"
  exit 1
fi

# -------- PHASE 2: assert artifacts present --------
printf "\n-- Phase 2: artifacts present after install --\n"

assert "skill mobile-readiness-check.md present" \
  "[ -f '${SKILLS_DIR_T}/mobile-readiness-check.md' ]"
assert "skill mobile-app-bootstrap.md present" \
  "[ -f '${SKILLS_DIR_T}/mobile-app-bootstrap.md' ]"
assert "skill mobile-template-pick.md present" \
  "[ -f '${SKILLS_DIR_T}/mobile-template-pick.md' ]"
assert "skill mobile-phone-preview.md present" \
  "[ -f '${SKILLS_DIR_T}/mobile-phone-preview.md' ]"
assert "kit state dir present" \
  "[ -d '${KIT_STATE_T}' ]"
assert "install manifest present" \
  "[ -f '${KIT_STATE_T}/install-manifest.json' ]"
assert "settings.json has selrai_mobile_kit key" \
  "jq -e '.selrai_mobile_kit' '${SETTINGS_T}' >/dev/null 2>&1"

# Plant a sentinel key in settings.json so we can verify it survives uninstall.
jq '. + {"_smoke_sentinel": "preserve-me"}' "${SETTINGS_T}" > "${SMOKE_HOME}/settings.tmp" \
  && mv "${SMOKE_HOME}/settings.tmp" "${SETTINGS_T}"

# -------- PHASE 3: uninstall --------
printf "\n-- Phase 3: uninstall --\n"
UNINSTALL_LOG="${SMOKE_HOME}/uninstall.log"

set +e
( CLAUDE_DIR="${CLAUDE_DIR_T}" bash "${KIT_ROOT}/uninstall.sh" --yes ) \
  > "${UNINSTALL_LOG}" 2>&1
UNINSTALL_EXIT=$?
set -e

assert "uninstall.sh exits 0" "[ ${UNINSTALL_EXIT} -eq 0 ]"

# -------- PHASE 4: assert artifacts removed --------
printf "\n-- Phase 4: artifacts removed after uninstall --\n"

assert "skill mobile-readiness-check.md removed" \
  "[ ! -f '${SKILLS_DIR_T}/mobile-readiness-check.md' ]"
assert "skill mobile-app-bootstrap.md removed" \
  "[ ! -f '${SKILLS_DIR_T}/mobile-app-bootstrap.md' ]"
assert "skill mobile-template-pick.md removed" \
  "[ ! -f '${SKILLS_DIR_T}/mobile-template-pick.md' ]"
assert "skill mobile-phone-preview.md removed" \
  "[ ! -f '${SKILLS_DIR_T}/mobile-phone-preview.md' ]"
assert "kit state dir removed" \
  "[ ! -d '${KIT_STATE_T}' ]"
assert "install manifest removed" \
  "[ ! -f '${KIT_STATE_T}/install-manifest.json' ]"

# -------- PHASE 5: settings.json integrity --------
printf "\n-- Phase 5: settings.json integrity --\n"

assert "settings.json still exists after uninstall" \
  "[ -f '${SETTINGS_T}' ]"
assert "selrai_mobile_kit key removed from settings.json" \
  "jq -e 'has(\"selrai_mobile_kit\") | not' '${SETTINGS_T}' >/dev/null 2>&1"
assert "sentinel key preserved in settings.json (other keys untouched)" \
  "jq -e '._smoke_sentinel == \"preserve-me\"' '${SETTINGS_T}' >/dev/null 2>&1"
assert "settings.json is valid JSON after uninstall" \
  "jq '.' '${SETTINGS_T}' >/dev/null 2>&1"

# -------- PHASE 6: idempotency --------
printf "\n-- Phase 6: second uninstall (idempotency) --\n"
UNINSTALL2_LOG="${SMOKE_HOME}/uninstall2.log"

set +e
( CLAUDE_DIR="${CLAUDE_DIR_T}" bash "${KIT_ROOT}/uninstall.sh" --yes ) \
  > "${UNINSTALL2_LOG}" 2>&1
UNINSTALL2_EXIT=$?
set -e

assert "second uninstall exits 0 (idempotent)" "[ ${UNINSTALL2_EXIT} -eq 0 ]"
assert "second uninstall prints nothing-to-remove message" \
  "grep -q 'Nothing to remove' '${UNINSTALL2_LOG}'"

# -------- result --------
printf "\npassed=%d/%d\n" "${PASSED}" "${TOTAL}"
if [ "${PASSED}" -eq "${TOTAL}" ]; then
  printf "RESULT: PASS\n"
  exit 0
else
  printf "RESULT: FAIL\n"
  exit 1
fi
