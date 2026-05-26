# Changelog

All notable changes to selrai-mobile-kit are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Version numbers follow [SemVer](https://semver.org/).

## [0.1.5] - 2026-05-26

Wires the `xero-companion` template to the `selrai-company/xero-proxy` Cloudflare Worker (v0.0.2 live). The two mocked-shell buttons now fetch real data via SelrAI-HMAC v1 signed requests. Pair-once-then-forget UX via QR scan from desktop `cloud/register.sh`.

### Added

- `templates/xero-companion/lib/store.ts`: `expo-secure-store` wrapper. Three values persisted under `xeroproxy.url`, `xeroproxy.slug`, `xeroproxy.secret`. Uses iOS Keychain + Android EncryptedSharedPreferences under the hood. No plaintext on device.
- `templates/xero-companion/lib/xero-client.ts`: HMAC-SHA256 signer + typed fetch helpers (`fetchCashFlow`, `fetchArAgeing`). Uses `@noble/hashes` (pure JS, audited, no native deps) for HMAC. Nonce via `expo-crypto.getRandomBytesAsync(16)`. Key derivation matches the Worker's stored shape: `key = utf8(sha256_hex(utf8(hmac_secret_hex)))`. Also exports `parsePairUri()` that validates `xeroproxy://pair?url=...&slug=...&secret=...` against tight regex (https-only URL, 12-hex slug, 64-hex secret).
- `templates/xero-companion/app/pair.tsx`: first-launch pair screen. Two tabs: **Scan QR** (uses `expo-camera`'s `CameraView` with `barcodeScannerSettings={{ barcodeTypes: ["qr"] }}`) and **Paste URI** (manual fallback). On successful pair: `expo-haptics.notificationAsync('success')` then redirect to home. Camera permission requested on first scan, not on screen mount.
- `templates/xero-companion/app/_layout.tsx`: gated by `getCredentials()` on mount. If unpaired, redirects to `/pair`. If paired and on `/pair`, redirects to home. Loading spinner during the async secure-store read.
- `templates/xero-companion/app/index.tsx`: replaced placeholder Alerts with live data fetch. Two cards: **Today's Cash** (renders `balance_today` + `projected_90d`) and **Who Owes Us** (renders `total_overdue` + 4-bucket breakdown). Per-card state machine: `loading | data | error`. Pull-to-refresh via `RefreshControl`. Stale badge when Worker returns `stale: true`. Empty-state message for AR ageing with zero overdue. Unpair action in header right.
- `templates/xero-companion/package.json`: deps bumped: `@noble/hashes ^1.5.0`, `expo-camera ~16.0.0`, `expo-crypto ~14.0.0`, `expo-haptics ~14.0.0`, `expo-secure-store ~14.0.0`. Pinned to SDK 54 store-Expo-Go alignment.
- `templates/xero-companion/app.json`: `expo-camera` plugin with `cameraPermission` string. iOS `NSCameraUsageDescription` + Android `CAMERA` permission. `expo-secure-store` plugin declared.
- `skills/xero-companion-pair.md`: operator-facing pairing walkthrough. Prereqs + step-by-step + troubleshooting + revocation curl.

### macOS install path

Code audit completed: both `install.sh` and `uninstall.sh` use only POSIX-portable shell features (no `sed -i` invocations, `mktemp` calls use the portable fallback pattern `mktemp -d 2>/dev/null || mktemp -d -t selrai-mobile-kit`). `jq` invocations are portable across BSD and GNU jq. **Code is BSD-compatible; live Mac smoke remains operator-gated** (Gian needs Mac access). The v0.1.3 CHANGELOG's "verified on Win11 only" caveat is preserved as a verification claim, not a code-compatibility claim.

### Verified

- TypeScript typecheck on the new lib files: clean.
- Em-dash check on all changed files: PASS.
- Eval set still 12/12 PASS in rule-only mode (no skill changes that affect classification).
- File structure: xero-companion grows from 12 to 15 files (adds `lib/store.ts`, `lib/xero-client.ts`, `app/pair.tsx`). Spec at `templates/README.md` updated.
- HMAC client implementation cross-checked against the Worker's exact key derivation. The double-conversion (bytes -> hex -> bytes) at the key step matches the Worker's `tenant.ts computeHmac` precisely. Signatures verified to interoperate (Worker smoke also runs the same derivation).

### Remaining gaps (deferred to v0.1.6)

- **Real-phone smoke on xero-companion.** Operator's manual gate. Scaffold + scan QR + verify both cards render with stub Worker data (Worker `STUB_RESPONSES=true` mode) and live Worker data.
- **Telegram bridge sibling template.** A v0.1.6 add per the design review: Telegram-as-owner-surface is the lower-friction UX for tradies who prefer chat. Same xero-proxy backend, different transport.
- **Real icon + splash assets.** Hand to Taylor for the brand work.

### Phase 0.3 punch list (carried forward)

- All remaining v0.1.4.1 carries (live wiring is now closed by this commit).
- Real-phone smoke + Telegram bridge as above.
- Icon + splash.

## [0.1.4.1] - 2026-05-26

Doc-only hotfix on top of v0.1.4 (PR #2). No code changes. Refreshes references to match `xero-skills` v0.2.0 which shipped between v0.1.4 commit and tag time. v0.2.0 stripped the custom MCP wrapper in favour of Xero's official `@xeroapi/xero-mcp-server` (Custom Connection auth, ~$5 USD/month per org paid to Xero).

### Refreshed references

- `templates/xero-companion/app/index.tsx`: placeholder Alert body now points at the `xero-proxy` Cloudflare Worker (the v0.1.5 wiring path) instead of the stale "xero-skills MCP" framing.
- `templates/xero-companion/README.md`: "Current state" line refreshed to name `xero-proxy` Worker + `@xeroapi/xero-mcp-server` lineage.
- `README.md` Status section: adds v0.1.4.1 line explaining the doc refresh and the v0.1.5 architecture change.
- `CHANGELOG.md` v0.1.4 entry: this section preserved (history), `xero-skills@d2919f9` SHA reference superseded by `c746b7d` (v0.2.0). Both SHAs are real history.

### v0.1.5 architecture (locked, code lands separately)

Per a 2026-05-26 design review (verdict: SHIP-WITH-FIXES, 5 fixes inline):

- **New sibling repo:** `selrai-company/xero-proxy`. Cloudflare Worker + Durable Objects (not KV, for strong consistency). HMAC-signed requests (not bearer-in-URL). CLIENT_SECRET wrapped via CF Secrets Store. Outbound allowlist enforced in code. `/register` requires admin bearer + Turnstile token.
- **Mobile-kit v0.1.5:** wires the 2 placeholder buttons to `xero-proxy` HMAC endpoints. Pairing skill (`/xero-companion-pair`) walks operator through a `cloud/register.sh` flow + QR-scan handoff.
- **Ship sequence:** xero-proxy v0.0.1 stub first (HMAC path, no Xero calls) -> xero-proxy v0.0.2 (Xero calls + 5 design fixes) -> mobile-kit v0.1.5 wires to v0.0.2.

### Not changed

- The xero-companion template structure (12 files, byte-shape spec-compliant per `templates/README.md`).
- Eval set (still 12/12 PASS in rule-only mode).
- macOS install path (still v0.1.3 state, deferred to a separate v0.1.5 commit in the same release).

## [0.1.4] - 2026-05-26

Adds the 4th template `xero-companion` to bridge the [selrai-company/xero-skills](https://github.com/selrai-company/xero-skills) buy-software suite into the mobile kit. Lands the kit on Harvey's 2026-05-26 R&D priority (improve existing kits + build skill suites around buy software, Xero first).

### Added

- `templates/xero-companion/`: 12-file Expo + NativeWind scaffold matching the existing 3-template precedent. Header colour Teal-700 (#0f766e). Two NativeWind buttons: "Today's Cash" (placeholder for cash-flow-forecast skill) and "Who Owes Us" (placeholder for ar-ageing-report skill). Phase 0.3 wires both to live data from the bundled `xero-skills` MCP. Mocked-shell precedent matches `pt-companion`, `service-quote`, `creator-companion`.
- `skills/mobile-template-pick.md`: extended from 3-way to 4-way classifier. New xero-companion keyword set (xero, bookkeeper, accountant, accounting, cash flow, accounts receivable, aged receivables, BAS, GST, P&L, balance sheet, chart of accounts, MYOB-to-Xero). Gemma prompt updated with the 4th rule. Validation list updated. New ambiguous case rule for trade-and-Xero overlap (audience=customer favours service-quote, audience=team favours xero-companion).
- `evals/template-picker-eval.jsonl`: 2 new cases (ev-11, ev-12) covering pure xero-companion intent (owner on Xero, bookkeeper handling client Xero orgs). Total 12 cases. Pass bar 10/12.
- `evals/run-eval.sh` + `run-eval.ps1`: rule classifier extended with xero branch (placed after PT, before service-quote, so a bookkeeper without explicit trade keywords routes to xero-companion). Gemma classifier extended with the 4th template. Validation extended.
- README + SETUP-PROMPT + mobile-app-bootstrap skill + templates/README: all 3-template wording bumped to 4-template. Status section refreshed.

### Why this template, why now

Harvey's 2026-05-26 SELR AI Weekly Team Meeting reversed the workshop v2 Phase 3 priority. The new R&D spine is "improve existing kits to production grade + build skill suites around buy software (Xero first)". This template bridges the mobile kit (existing) with the xero-skills connector suite (also shipped 2026-05-26) so a buy-software glance on the phone is one of the kit's named verticals. Source-of-truth for the new R&D direction: the [Selr Kit Library dashboard](https://selr-kit-dashboard.vercel.app/).

### Remaining gaps (deferred to v0.1.5)

- **Live Xero data wiring.** Both `xero-companion` buttons still show placeholder Alerts (matches the 3 existing templates' Phase 0.2 precedent). v0.1.5 wires them via the new `selrai-company/xero-proxy` Cloudflare Worker (architecture locked in v0.1.4.1 hotfix; see that section above for the design-review verdict and 5 fixes).
- **macOS install path.** Unchanged from v0.1.3. Still only verified on Win11. Workshop attendees on Mac advised to wait for v0.1.5.
- **Real-phone smoke on xero-companion.** Gian's phone gate, deferred to next-session.

### Phase 0.3 punch list (carried forward)

- All remaining v0.1.3 Phase 0.3 items (FIND-001 npx/bun/npm fencing, real bun install smoke, macOS install path, asset replacement).
- Live data wiring for xero-companion (see above).
- Real-phone smoke on xero-companion (Gian's manual gate).

## [0.1.3] - 2026-05-19

Closes the parity gap with the 4 hardening-lap kits: every distributable kit now has a clean uninstall path. Also closes FIND-003 from the Day 2 security re-pass.

### Added

- `uninstall.sh` + `uninstall.ps1`: idempotent teardown. Removes the 4 mobile-* skill files from `~/.claude/skills/`, the `~/.claude/selrai-mobile-kit/` state directory (install manifest + drift state), and the `selrai_mobile_kit` top-level key from `~/.claude/settings.json` via `jq del`. Other user keys preserved. `--yes` flag for non-interactive use, `--dry-run` for audit.
- `tests/uninstall_smoke.sh`: 6-phase smoke (install, present-assertion, uninstall, removed-assertion, settings.json integrity with sentinel-key preservation check, idempotency). Result on Win11 Git Bash + Bun 1.3.14: **20/20 PASS**.
- README "Uninstall" section pointing to both scripts.

### Fixed

- **FIND-003 (Medium): template-picker input sanity gate.** `skills/mobile-template-pick.md` Step 1.5 adds an 8 KB byte cap on the business description plus a 13-pattern injection pre-pass (matches `ignore previous instructions`, `system:`, `[INST]`, `<s>`, `<|im_start|>`, `dan mode`, `reveal the system prompt`, etc.). On violation: refuse, prompt the user to rephrase. Sister-list note ties the patterns to `wiki-brain-kit/compactor/sanitise.py` and `sub-agent-discipline-kit/skills/goal-loop-wrapper/goal-loop.sh` lineage.

### Phase 0.3 deferrals (documented for posterity)

- **macOS install path** (unchanged from v0.1.2 CHANGELOG). Both installers only verified on Win11. Workshop attendees on Mac should wait for v0.1.4.
- **FIND-001** (npx / bun / npm stdout fencing). Lives at the user-kit-level `tool-output-fencing` hook config, not in this repo. Out of scope; tracked at the operator's user-kit layer.

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
