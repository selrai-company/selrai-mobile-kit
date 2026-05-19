#!/usr/bin/env bash
#
# selrai-mobile-kit, uninstaller (macOS / Linux / Git Bash on Windows)
#
# Removes:
#   - 4 mobile-* skill files from ~/.claude/skills/
#   - ~/.claude/selrai-mobile-kit/ (manifest + drift state)
#   - .selrai_mobile_kit key from ~/.claude/settings.json (via jq)
#
# Flags:
#   --yes    non-interactive (no confirmation prompt)
#   --dry-run  print what would be removed, do not remove anything
#
# Idempotent. Safe to run when nothing is installed (exits 0).
# Exit codes: 0 success, 1 user cancel, 2 filesystem error.
#

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS_DIR="${CLAUDE_DIR}/skills"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
KIT_STATE_DIR="${CLAUDE_DIR}/selrai-mobile-kit"

YES=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)     YES=1;     shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '3,19p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) printf "uninstall.sh: unknown arg: %s\n" "$1" >&2; exit 2 ;;
  esac
done

bold()  { printf "\033[1m%s\033[0m\n" "$1"; }
ok()    { printf "  \033[32mok\033[0m %s\n" "$1"; }
skip()  { printf "  \033[33mskip\033[0m %s\n" "$1"; }
plan()  { printf "  \033[36mplan\033[0m %s\n" "$1"; }
err()   { printf "  \033[31merr\033[0m %s\n" "$1" >&2; }

# ---- build removal list (for confirmation count) ----
SKILLS=(
  "mobile-readiness-check.md"
  "mobile-app-bootstrap.md"
  "mobile-template-pick.md"
  "mobile-phone-preview.md"
)

echo
bold "selrai-mobile-kit, uninstaller"
if [[ "$DRY_RUN" -eq 1 ]]; then bold "(dry-run, no changes)"; fi
echo

# Count items actually present so the confirmation is accurate.
ITEM_COUNT=0
for skill in "${SKILLS[@]}"; do
  [[ -f "${SKILLS_DIR}/${skill}" ]] && ITEM_COUNT=$((ITEM_COUNT + 1))
done
[[ -d "${KIT_STATE_DIR}" ]] && ITEM_COUNT=$((ITEM_COUNT + 1))
if [[ -f "${SETTINGS_FILE}" ]] && command -v jq >/dev/null 2>&1; then
  jq -e '.selrai_mobile_kit' "${SETTINGS_FILE}" >/dev/null 2>&1 && \
    ITEM_COUNT=$((ITEM_COUNT + 1))
fi

if [[ "${ITEM_COUNT}" -eq 0 ]]; then
  bold "Nothing to remove (kit not installed)."
  echo
  exit 0
fi

# ---- confirmation prompt ----
if [[ "${YES}" -eq 0 && "${DRY_RUN}" -eq 0 ]]; then
  printf "This will remove %d item(s) installed by selrai-mobile-kit.\n" "${ITEM_COUNT}"
  printf "Continue? [y/N] "
  read -r REPLY
  case "${REPLY}" in
    [Yy]*) ;;
    *) printf "Cancelled.\n"; exit 1 ;;
  esac
  echo
fi

# ---- remove helpers ----
do_rm_file() {
  local target="$1"
  if [[ ! -e "${target}" ]]; then
    skip "already removed: ${target}"
    return
  fi
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    plan "would remove file: ${target}"
  else
    if rm -f "${target}" 2>/dev/null; then
      ok "removed: ${target}"
    else
      err "could not remove: ${target}"
      return 2
    fi
  fi
}

do_rm_dir() {
  local target="$1"
  if [[ ! -e "${target}" ]]; then
    skip "already removed: ${target}"
    return
  fi
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    plan "would remove dir: ${target}"
  else
    if rm -rf "${target}" 2>/dev/null; then
      ok "removed dir: ${target}"
    else
      err "could not remove dir: ${target}"
      return 2
    fi
  fi
}

# ---- 1. Skills ----
bold "Skills:"
for skill in "${SKILLS[@]}"; do
  do_rm_file "${SKILLS_DIR}/${skill}"
done

# ---- 2. Kit state dir (manifest + drift state) ----
echo
bold "Kit state:"
do_rm_dir "${KIT_STATE_DIR}"

# ---- 3. settings.json surgery ----
echo
bold "settings.json:"
if [[ ! -f "${SETTINGS_FILE}" ]]; then
  skip "settings.json not found (nothing to patch)"
else
  if ! command -v jq >/dev/null 2>&1; then
    err "jq not found -- cannot remove selrai_mobile_kit key. Remove it manually from ${SETTINGS_FILE}."
  else
    if ! jq -e '.selrai_mobile_kit' "${SETTINGS_FILE}" >/dev/null 2>&1; then
      skip "selrai_mobile_kit key already absent from settings.json"
    elif [[ "${DRY_RUN}" -eq 1 ]]; then
      plan "would delete .selrai_mobile_kit from ${SETTINGS_FILE}"
    else
      TMP_SETTINGS="$(mktemp)"
      if jq 'del(.selrai_mobile_kit)' "${SETTINGS_FILE}" > "${TMP_SETTINGS}" \
         && mv "${TMP_SETTINGS}" "${SETTINGS_FILE}"; then
        ok "removed selrai_mobile_kit key from ${SETTINGS_FILE}"
      else
        rm -f "${TMP_SETTINGS}" 2>/dev/null || true
        err "jq patch failed -- ${SETTINGS_FILE} untouched"
        exit 2
      fi
    fi
  fi
fi

echo
bold "Done."
echo
