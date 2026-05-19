# Changelog

All notable changes to selrai-mobile-kit are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Version numbers follow [SemVer](https://semver.org/).

## [0.1.2] - 2026-05-18

Closes the piped-exec install path (CONFIRM-005) and brings every template to real-phone-verified status.

### Fixed

- **CONFIRM-005: piped-exec install path.** The `curl ... | bash` and `iwr ... | iex` distribution paths (the standard "one-liner install" pattern) previously silently no-op'd the skill copy because `$0` / `$PSScriptRoot` does not resolve to a real script path under those modes. Both `install.sh` and `install.ps1` now detect this (script source is not a regular file OR adjacent `skills/` + `tools/` dirs missing), `git clone` the repo to a temp dir, proceed normally against the cloned source, and clean up the temp dir on EXIT.
- `install.sh` detection hardened: uses `BASH_SOURCE[0]` first, then `-f "$0"`. Avoids the false-negative where `dirname "bash"` resolves to `.` and the caller's cwd happens to have a `skills/` dir by coincidence. Both `skills/` AND `tools/` must exist adjacent to consider the dir a real kit checkout.
- New `tests/piped_exec_smoke.sh` (13 assertions): runs `install.sh` through stdin from a clean cwd (simulates `curl ... | bash` from `$HOME`), verifies piped-exec detection fires, git clone completes, drift-check runs from the cloned dir, all 4 skills install, settings.json gets the kit block, second invocation is idempotent. Result: 13/13 PASS locally.

### Verified

- Real-phone smoke on **all 3 templates**: `pt-companion`, `service-quote`, `creator-companion`. Expo Go 54.0.8 on Gian's phone, each template bundled cleanly via Metro on LAN, home screen rendered with NativeWind-styled buttons, both placeholder alerts fired correctly. No errors. Closes the gap v0.1.1 left for `service-quote` + `creator-companion`.

### Remaining gap (one, deferred to Phase 0.3)

- **macOS install path.** Both installers have only run on Win11 (Git Bash for `install.sh`, pwsh for `install.ps1`) to date. macOS would test the BSD `sed -E`, BSD `jq`, and BSD `mktemp` paths which differ subtly from the GNU equivalents `install.sh` was authored against. Phase 0.3 gate: smoke when Mac access is available. Workshop attendees on Mac are advised to wait for v0.1.3.

## [0.1.1] - 2026-05-18

Hot follow-up to 0.1.0. **0.1.0 was DOA on real phones** and is superseded.

### Fixed

- **Critical: Expo SDK pin dropped from 55.0.24 to 54.0.34.** Found on Day 3 real-phone smoke test: store-installed Expo Go (`54.0.8` at smoke time) only supports SDK 54. Pinning to SDK 55 produced "Project is incompatible with this version of Expo Go" on first QR scan. Non-technical workshop attendees install Expo Go from the App Store / Play Store; the kit must pin to what the store currently ships, not what is `latest` on npm. SDK 55 was tagged `latest` on npm registry but Expo Go on the stores had not yet caught up.
- 3 template `package.json` files realigned to canonical SDK 54 deps per `expo-template-blank-typescript@54.0.44`:
  - `expo ~54.0.33`, `react 19.1.0`, `react-native 0.81.5`, `expo-status-bar ~3.0.9`
  - `expo-router ~5.1.11` (highest stable 5.x line, peer `expo: "*"` accepts SDK 54)
  - `@types/react ~19.1.0`, `typescript ~5.9.2`
- `install.sh` line 16 `EXPO_SDK_PIN` and `install.ps1` line 15 `$ExpoSdkPin` both refreshed to `54.0.34`, with a comment block citing the store-Expo-Go gating rule.
- 3 template `README.md` Stack sections refreshed to the SDK 54 dep tree.

### Process change

- New kit policy: SDK pin tracks the **store Expo Go**, not npm `latest`. Phase 0.3 SDK bump only after a real-phone smoke re-passes.

### Verified

- Real-phone smoke 2026-05-18 PM AEST: scaffold `pt-companion` on Win11 + Bun 1.3.14 on D: drive (avoiding C: pressure) + Metro on LAN `192.168.1.10:8081` + Expo Go `54.0.8` on Gian's phone. QR scanned, bundling completed, home screen rendered with the two `Pressable` buttons styled by NativeWind, both buttons fire the placeholder Alert. No errors. This is the gate v0.1.0 failed.

## [0.1.0] - 2026-05-18

First Phase 0.2 ship-locked release. Workshop / Skool distributable.

### Added

- Value-led `README.md`: "ship a working mobile app to your own phone in a half-day, no Xcode, no Android Studio."
- `SETUP-PROMPT.md`: non-technical user's paste-into-Claude-Code entry. Three plain-English questions.
- 4 Claude Code skills under `skills/`:
  - `mobile-readiness-check`: verify Node 20+, Bun, disk, npm reachability, Expo tunnel. Hotspot fallback baked in. No raw error logs.
  - `mobile-template-pick`: local-Gemma classifier with deterministic rule-based fallback. Picks one of three templates from a one-sentence business description.
  - `mobile-app-bootstrap`: orchestrate Anthropic plugin verification, template copy, NativeWind setup, `bun install`. Single-sentence failures. Gates on Anthropic plugin presence.
  - `mobile-phone-preview`: procedural walk-through for Expo Go QR pairing. Hotspot fallback.
- 3 domain-vertical templates under `templates/`:
  - `pt-companion` (blue, personal trainer): home screen + workout / client check-in entry points.
  - `service-quote` (green, tradies / on-site service): home screen + quote / job-list entry points.
  - `creator-companion` (purple, content creator): home screen + content-prompt / GHL passthrough entry points.
  - Each template scaffolds with Expo SDK 55.0.24 + RN 0.83.6 + React 19.2.0 + Expo Router 55.0.x + NativeWind 4.2.x + Bun.
  - Accessibility labels, hints, roles on every interactive element. WCAG AA contrast verified on all three brand colors.
- `evals/` (template picker ground truth):
  - 10 golden prompts (3 PT, 3 service, 3 creator, 1 ambiguous fitness-creator case).
  - `run-eval.sh` and `run-eval.ps1` harnesses. Pass bar 8/10. Both score 10/10 in rule-fallback mode.
- `tools/anthropic-drift-check.sh`: per-install drift detector against `claude.com/plugins/expo`. Fires alarm on >15% description Levenshtein, version change, or any of 9 keyword triggers (`template`, `starter`, `wizard`, `onboard`, `non-technical`, `scan`, `QR`, `Expo Go`, `phone preview`). Non-blocking on network failure.
- Idempotent installers (`install.sh`, `install.ps1`):
  - Friendly tooling-check failures (one sentence each).
  - Per-install drift manifest at `~/.claude/selrai-mobile-kit/install-manifest.json`.
  - Skill copy from repo `skills/` to `~/.claude/skills/`.
  - `tool-output-fencing` soft-warn (non-blocking security recommendation).
  - `jq`-merged egress allowlist into `~/.claude/settings.json` (5 hosts: registry.npmjs.org, cdn.expo.dev, u.expo.dev, api.expo.dev, exp.host).
- `docs/prior-art.md`: 30-minute repo crawl + Anthropic Expo plugin overlap analysis (per memory rule `repo-crawl-before-rd-kit`).
- `docs/anthropic-overlap.md`: full security audit with overlap matrix, premortem, drift-check spec, and Day 2 re-pass. Verdict SHIP.
- `.gitignore` covering Node, Bun, Expo, RN, OS junk.

### Fixed

- Drift-check `og:description` extraction now handles both attribute orders. The Anthropic plugin page renders as `content="..." property="og:description"` (content-first). Previous regex assumed property-first. Fix: two-pass extraction (match the meta tag, then pull `content` regardless of order). Removes the prior fallback that silently hashed Webflow header JS / CSS junk and masked real drift. Closes CONFIRM-004 from the Phase 0.2 Day 1 security audit.
- Template `README.md` Stack sections corrected from "Expo SDK 54" to "Expo SDK 55 (55.0.24)" plus full dep list (FIND-002 from Day 2 security re-pass).
- Expo SDK pin corrected from a stale `52.0.0` default to the live `55.0.24` (npm registry dist-tag `latest` and `sdk-55`). Verified against the canonical SDK 55 template (`expo-template-blank-typescript@sdk-55`).

### Closed audit items

- CONFIRM-001 (drift-check script written and wired).
- CONFIRM-002 (`tool-output-fencing` activation verified across 6 ingestion paths; soft-warn fires correctly when the skill is absent).
- CONFIRM-003 (Expo SDK semver pin verified live).
- CONFIRM-004 (drift-check `og:description` extraction works against the actual page structure).

### Phase 0.3 punch list (non-blocking)

- CONFIRM-005 (`$PSScriptRoot` in piped-exec context).
- FIND-001 (extend PostToolUse fencing hook to cover `npx | bun | npm`).
- FIND-003 (byte cap + injection pre-pass on the template-picker business-description input).
- Real `bun install` smoke on a Bun-equipped machine (every workshop attendee will have Bun installed per the kit's prereq).
- Phone-side QR scan smoke (Gian's manual gate).
- macOS install path verified on a real Mac.

### Known prereqs (workshop attendee or Skool member)

- Node 20+ on PATH.
- Bun on PATH (install at https://bun.sh).
- `jq` on PATH (install via Homebrew on mac, apt on Linux, scoop on Windows).
- Expo Go on the user's phone (App Store / Play Store).
- Phone on the same Wi-Fi as the host machine, or hotspot from the phone.
- Optional: Ollama with Gemma 4 or Gemma 2:2b for the local-LLM template picker. Without Ollama, the kit falls back to a deterministic keyword-rule classifier (10/10 on the bundled eval set).

### Distribution

- Repo: https://github.com/selrai-company/selrai-mobile-kit (private under selrai-company per the locked 2026-05-11 R&D repo policy).
- Phase 0.3 gates with Harvey for workshop module / Skool drop placement.
