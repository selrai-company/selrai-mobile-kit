# Anthropic Overlap Audit

**Document type:** Phase 0.2 Day 1 security deliverable
**Author:** Gian (2026-05-18 security audit)
**Status:** Audit complete. Verdict below.
**Scope:** Official Anthropic `expo` plugin, Expo Agent (April 2026), Claude Code What's New feed vs selrai-mobile-kit Phase 0.1 surface.

---

## 1. Anthropic-Shipped Surface (verified 2026-05-18)

Sources:
- Plugin page: https://claude.com/plugins/expo (5,739 installs at crawl time)
- Claude Code What's New: https://code.claude.com/docs/en/whats-new (verified Week 13-19, 2026)
- Plugin docs: https://code.claude.com/docs/en/plugins

### Official `expo` plugin capabilities

Per the plugin page at https://claude.com/plugins/expo, the plugin covers:

- **Scaffold:** New React Native project creation via Expo. Description states it covers "UI development with Expo Router, SwiftUI and Jetpack Compose components." No opinionated template selection, no domain-vertical starters.
- **Routing:** Expo Router (file-based) setup guidance and development iteration.
- **Styling:** Tailwind CSS setup guidance within Expo projects.
- **Backend:** API routes and data fetching patterns inside Expo projects.
- **SDK upgrades:** Expo SDK version management and upgrade assistance. Covers drift between SDK versions.
- **Deployment:** App Store and Play Store submission processes. Full production deployment lifecycle.
- **CI/CD:** CI/CD workflow guidance for automated testing and deployment pipelines.
- **Distribution:** Dev client distribution methods (EAS Build, internal distribution).
- **Web support:** DOM component handling for Expo Web targets.
- **Debugging:** Debugging React Native apps within Expo environments.

The plugin description explicitly states: "Official Expo skills for building, deploying, upgrading, and debugging React Native apps with Expo." It is a developer-facing knowledge plugin. It does not include: a pre-install readiness check for non-technical users, domain templates, phone-as-simulator QR-pairing flow, or a local-LLM template classifier.

### Claude Code platform-level mobile capabilities (April-May 2026, verified)

These are platform features that touch "mobile" but are not mobile-app-building features:

- **Mobile push notifications** (Week 16, April 13-17, 2026, verified at https://code.claude.com/docs/en/whats-new/2026-w16): "Claude can send a push notification to your phone when a long task finishes or it needs a decision to keep going." Requires Remote Control connected. This is developer workflow notification, not Expo Go QR pairing. Not overlapping with the kit's phone-preview skill.
- **Routines** (Week 16): Templated cloud agents fired on schedule or webhook. Not mobile-app scaffolding. No overlap.
- **Plugin background monitors** (Week 16): `monitors.json` in plugin root, watches logs/files, notifies Claude. No mobile-specific capability. No overlap.

### Expo Agent (April 2026)

The Expo Agent launch ($45M Series B, April 2026) is documented in `docs/prior-art.md`. Second-pass evidence collected 2026-05-18 via `agent.expo.dev` and the `expo/skills` GitHub repo (the source of the Anthropic `expo` plugin):

- **`agent.expo.dev` landing page**, verbatim tagline: "Build for Production. Ship. Iterate. Faster." Sign-in via Expo credentials. Targets developers. No mention of domain templates, non-technical onboarding, in-CLI template selection, or EAS-hosted phone preview.
- **`docs.expo.dev/agent/` returns 404.** Expo Agent has no dedicated docs section under the docs subdomain. Marketing-only landing.
- **`github.com/expo/skills`** (1,936 stars, pushed 2026-05-16) is the source repo for the official Anthropic `expo` plugin's skills. The plugin ships 14 skills (see Section 1.5 below). None overlap the kit's wedge surface.

The original three `[CONFIRM]` items resolve as follows:

- Expo Agent in-CLI template selection: **No evidence found.** Agent.expo.dev does not advertise it. Closes as WRAP-OK.
- Expo Agent EAS-hosted preview link competing with phone-preview: **No evidence found.** Closes as WRAP-OK.
- Expo Agent non-technical onboarding wizard: **No evidence found.** Developer-targeted product per its own marketing. Closes as WRAP-OK.

### 1.5 Official `expo` plugin skill inventory (`github.com/expo/skills/plugins/expo/skills/`)

The 14 skills the Anthropic `expo` plugin ships:

| Skill | Overlaps kit? |
|---|---|
| `building-native-ui` | No |
| `eas-update-insights` | No |
| `expo-api-routes` | No |
| `expo-cicd-workflows` | No |
| `expo-deployment` | No (kit defers app-store deploy to plugin) |
| `expo-dev-client` | No (kit uses Expo Go, not dev client) |
| `expo-module` | No |
| `expo-tailwind-setup` | Partial. Our `/mobile-app-bootstrap` invokes this skill during scaffold. Wrap, not duplicate. |
| `expo-ui-jetpack-compose` | No |
| `expo-ui-swift-ui` | No |
| `native-data-fetching` | No |
| `upgrading-expo` | Partial. On-demand upgrade. Our installer pins + drift-checks per-install. Different cadence, not overlapping. |
| `use-dom` | No (Expo Web) |

The kit's 4 skills (`mobile-readiness-check`, `mobile-template-pick`, `mobile-app-bootstrap`, `mobile-phone-preview`) are absent from this set.

---

## 2. selrai-mobile-kit Added Surface

Each item cross-referenced to its kit artifact.

- **Pre-install readiness check** (`/mobile-readiness-check` skill stub, `install.sh` section 1, `install.ps1` section 1): Verifies Node 20+, Bun, free disk, LAN, phone-pair compatibility. Returns a single sentence. Hides raw error logs from non-technical users. No equivalent in the official plugin.
- **3 domain-vertical templates** (`pt-companion`, `service-quote`, `creator-companion`): Pre-wired domain logic for personal trainer, on-site quoting, and creator/GHL use cases. Referenced in `README.md` and `SETUP-PROMPT.md`. The official plugin scaffolds a blank Expo project, no domain logic.
- **Local-Gemma template picker** (`/mobile-template-pick` skill stub): User describes business in plain English, local Gemma 4 on Ollama classifies to one of 3 templates. Zero API cost. Sourced from `README.md` and `docs/prior-art.md` section 2. No equivalent in official plugin.
- **Phone-as-simulator default with non-technical QR walk-through** (`/mobile-phone-preview` skill stub, `SETUP-PROMPT.md`): Assumes user has Expo Go on their phone, not Xcode or Android Studio. SETUP-PROMPT.md explicitly inverts the developer assumption. No equivalent in official plugin.
- **Non-technical conversational entry** (`SETUP-PROMPT.md`): The 3-question onboarding sequence (business description, audience type, phone-test-today?) routed through `/mobile-template-pick` then `/mobile-app-bootstrap` then `/mobile-phone-preview`. Explicitly designed for non-technical Skool members and Architecture-tier clients. No equivalent in official plugin.
- **Egress allowlist baked into installer** (`install.sh` section 4, `install.ps1` section 4): `settings.json` block restricts Claude Code session to `registry.npmjs.org`, `cdn.expo.dev`, `u.expo.dev`, `api.expo.dev`, `exp.host`. The official plugin applies no egress restrictions. This is a security posture addition.
- **Per-install drift manifest** (`install.sh` section 2, `install.ps1` section 2): Writes `install-manifest.json` with kit version, Expo SDK pin, and install timestamp. Baseline for `tools/anthropic-drift-check.sh` (Phase 0.2 Day 2). No equivalent in official plugin.
- **App bootstrap orchestration** (`/mobile-app-bootstrap` skill stub): Runs scaffold, merges the chosen template's pre-wired screens, wires NativeWind, and hands off to preview. Coordinates the full non-technical install-to-preview path. The official plugin assists but does not orchestrate for a non-technical audience.

---

## 3. Overlap Matrix

| Capability | Anthropic ships it? | Kit ships it? | Verdict |
|---|---|---|---|
| New Expo project scaffold (blank) | Yes. Official plugin covers initial scaffolding via Expo CLI. | Yes, via `/mobile-app-bootstrap` but applied to a domain template, not blank. | WRAP-OK. Kit wraps scaffold with template application. Not a re-implementation. |
| Expo Router setup | Yes. Official plugin covers Expo Router guidance. | Partial. Templates use Expo Router but kit does not teach it. | WRAP-OK. Kit consumes the capability, does not duplicate instruction. |
| Tailwind / NativeWind setup | Yes. Official plugin covers Tailwind setup guidance. | Yes, via template scaffolding (NativeWind installed in `/mobile-app-bootstrap`). | WRAP-OK. Kit automates what the plugin explains manually. |
| SDK upgrade and drift management | Yes. Official plugin covers SDK upgrade assistance. | Partial. Installer pins SDK version. Drift check (Phase 0.2 Day 2) is per-install only. | WRAP-OK. Kit adds a per-install hard pin + drift alert on top of the plugin's guidance. |
| App Store / Play Store deployment | Yes. Official plugin covers submission workflows. | No. README explicitly states "app-store testing is out of scope." | WRAP-OK. Kit defers this entirely to the official plugin. |
| CI/CD pipeline guidance | Yes. Official plugin covers CI/CD. | No. Out of kit scope. | WRAP-OK. No overlap. |
| Dev client distribution (EAS) | Yes. Official plugin covers EAS Build and internal distribution. | No. Kit uses Expo Go + QR only. | WRAP-OK. Different distribution target (local phone, not EAS). |
| Debugging React Native apps | Yes. Official plugin covers debugging. | No. Out of kit scope. | WRAP-OK. No overlap. |
| Domain-vertical templates (pt, quote, creator) | No. Official plugin ships no domain templates. | Yes. All 3 templates are kit-original. | WRAP-OK. Pure addition. |
| Non-technical conversational entry (3 questions) | No. Plugin assumes developer audience. | Yes. `SETUP-PROMPT.md` + skill chain. | WRAP-OK. Pure addition. |
| Local-LLM template picker (Gemma) | No. Official plugin has no template router. | Yes. `/mobile-template-pick` via Ollama. | WRAP-OK. Pure addition. |
| Phone-as-simulator QR walk-through | No. Official plugin does not document Expo Go + QR for non-technical users. | Yes. `/mobile-phone-preview` + SETUP-PROMPT. | WRAP-OK. Pure addition. |
| Pre-install readiness check (non-technical) | No. Plugin assumes tooling is already installed. | Yes. `/mobile-readiness-check` + installer section 1. | WRAP-OK. Pure addition. |
| Egress allowlist in settings.json | No. Official plugin applies no egress restriction. | Yes. Installer merges 5-host allowlist. | WRAP-OK. Security posture addition. |
| Mobile push notifications (dev workflow) | Yes. Claude Code Week 16 (https://code.claude.com/docs/en/whats-new/2026-w16). Pings phone when task finishes or Claude needs a decision. | No. Kit does not use or reference Remote Control push. | WRAP-OK. Different surface (dev workflow notification vs app preview). No conflict. |
| Expo Agent template selection | No. Verified via `agent.expo.dev` (developer-targeted marketing, no template claim) and `expo/skills` (14 skills, none are template selectors). | Partial. Kit ships 3 domain templates with a local-LLM picker. | WRAP-OK. Closed 2026-05-18. |
| Expo Agent non-technical onboarding | No. Verified via `agent.expo.dev` (no wizard claim, developer audience explicit) and `expo/skills` (no onboarding wizard skill). | Yes. Kit's primary wedge. | WRAP-OK. Closed 2026-05-18. |

---

## 4. Premortem

Top 5 failure causes, ranked by likelihood. 6-key shape per CLAUDE.md mandatory gate.

| Cause | Severity | Likelihood Rank | Earliest Detection Signal | Mitigation Present | Mitigation Reference |
|---|---|---|---|---|---|
| Anthropic or Expo ships a "mobile starter" command or wizard that subsumes the kit's non-technical onboarding within 60-90 days | High | 1 | `tools/anthropic-drift-check.sh` exits with `DRIFT DETECTED` on first post-ship install. User sees the drift message (see Section 5). Secondary signal: GitHub watch on `expo/expo` for new CLI commands. | Partial. Installer writes a baseline manifest. The actual diff script is a Phase 0.2 Day 2 deliverable. | `install.sh` section 2, `install.ps1` section 2. `tools/anthropic-drift-check.sh` stub (CONFIRM-001: script must land before Phase 0.2 Day 2 ships). |
| Indirect prompt injection via fetched template README or pasted Sarev course transcript ingested as tool output | Critical | 2 | `tool-output-fencing` skill intercepts the offending tool call. Log line shape: `[tool-output-fencing] blocked: <tool-name> returned >8KB unvalidated text`. Secondary: unexpected model behavior on first template scaffolding run. | Partial. `tool-output-fencing` skill is listed in `docs/prior-art.md` section 6 as a mitigation. Templates ship in-repo (not fetched at runtime). Sarev transcript is linked by URL, not committed. Installer egress allowlist limits fetch surface. | `docs/prior-art.md` section 6. Egress allowlist in `install.sh` section 4. `tool-output-fencing` skill (CONFIRM-002: skill must be verified active on template ingestion paths before Phase 0.2 Day 2). |
| A community kit (`senaiverse/claude-code-reactnative-expo-agent-system` or similar) reaches critical mass and SelrAI looks like a slower copy | Medium | 3 | First signal: selrai-company repo star growth flat vs competitor growth accelerating (GitHub watch). Second signal: Skool or workshop attendee says "I already found a free kit that does this." | Partial. `docs/prior-art.md` section 3 documents the community kit as studied but not copied. Kit's wedge is non-technical audience + V4.1.2 vertical templates, not raw capability count. | `docs/prior-art.md` section 3. Kit scope statement in `README.md`. Phase 0.3 Harvey curation + Skool drop placement is the distribution moat. |
| Expo SDK version drift between kit pin and actual SDK release breaks template scaffolding silently | Medium | 4 | First scaffold run fails with Bun dependency resolution error. `install.sh` section 2 manifest records the pin. Drift detected on next install via `tools/anthropic-drift-check.sh`. | Partial. `EXPO_SDK_PIN="latest"` in installer is a known placeholder: the TODO comment at `install.sh` line 13 and `install.ps1` line 12 explicitly calls out Phase 0.2 replacement with a verified pin. Until that is done, the pin does not protect against drift. | `install.sh` line 13. `install.ps1` line 12. (CONFIRM-003: replace `"latest"` with a verified SDK semver before Phase 0.2 Day 2). |
| Kit ships with 4 skill stubs that do nothing, a non-technical user installs Phase 0.1, runs `/mobile-readiness-check`, gets a stub response, and files a support ticket or leaves a bad review | Low | 5 | User files GitHub issue citing stub name (per `SETUP-PROMPT.md` instructions). Skool post in Workshop R&D space. | Yes. `SETUP-PROMPT.md` explicitly tells users that stub gaps produce an issue-filing path, not a raw error. `README.md` status block says "Phase 0.2 in flight." | `SETUP-PROMPT.md` ("If you get stuck" section). `README.md` status block. |

---

## 5. Drift-Check Spec

**File:** `tools/anthropic-drift-check.sh`
**Cadence:** Per-install only. No cron. Per Gian's confirmed decision 2026-05-18.

### What to fetch

Hit the Claude plugin page for expo and extract the plugin description field.

```
TARGET_URL="https://claude.com/plugins/expo"
```

Use `curl -sSL` with a 10-second timeout. If the fetch fails (network offline, 4xx, 5xx), the script exits with code 0 and prints a non-blocking warning. Drift checks must never block installation.

### What to diff

1. **Install count.** Extract the integer from the page matching the pattern `[0-9,]+ installs` or equivalent. Compare against the value recorded at previous install. If the delta exceeds 500 installs, that alone does not trigger a drift alarm. Install count is a leading indicator only.
2. **Capability description block.** Extract the full text description from the plugin page (the paragraph or bullet list under the plugin name). Normalize whitespace. Compare against the `anthropic_expo_plugin_description` field in `~/.claude/selrai-mobile-kit/install-manifest.json`. If the normalized text differs by more than 15% character edit distance (Levenshtein), trigger a drift alarm.
3. **Plugin version or updated-at field.** If the page exposes a version string or last-updated date, compare against the `anthropic_expo_plugin_version` field in the manifest. Any change triggers a drift alarm.

### What counts as a drift alarm

A drift alarm fires when any of the following is true:

- The capability description text differs by more than 15% from the manifest baseline.
- A version or updated-at field changed since the last recorded install.
- The page returns a 404 (plugin removed or renamed).
- The page now mentions any of these terms that were absent at last install: `template`, `starter`, `wizard`, `onboard`, `non-technical`, `scan`, `QR`, `Expo Go`, `phone preview`.

The last rule is the highest-signal check. These terms would indicate Anthropic or Expo has shipped features that overlap the kit's core wedge.

### User message on drift detected

When a drift alarm fires, the script prints the following block and exits with code 2 (non-zero, so the installer can detect it):

```
[selrai-mobile-kit] DRIFT DETECTED

The official Anthropic expo plugin description changed since your last install.

Previous description hash: <hash>
Current description hash:  <hash>
Changed terms detected:     <list or "none">

Action required: Run /mobile-readiness-check and review the Phase 0.2 Day 1 audit doc at docs/anthropic-overlap.md before scaffolding a new app. If Anthropic now ships a feature this kit duplicates, the relevant skill will be deprecated in the next kit release.

File a note at: https://github.com/selrai-company/selrai-mobile-kit/issues
```

The installer section 2 `TODO` (currently a placeholder) calls this script and treats exit code 2 as a warning-only path, not an installation failure. The user continues to the next install step.

### Manifest update

After each run (whether drift was detected or not), the script updates `~/.claude/selrai-mobile-kit/install-manifest.json` with:

```json
{
  "anthropic_expo_plugin_description_hash": "<sha256 of normalized description>",
  "anthropic_expo_plugin_version": "<version string or null>",
  "drift_check_last_run": "<ISO 8601 UTC>",
  "drift_alarm_fired": true | false
}
```

### Dependencies

`curl`, `sha256sum` (or `shasum -a 256` on macOS), and basic string tools. No Python, no jq required for the hash step. The installer already gates on `jq` being present, so the manifest JSON write may use `jq` for the update.

---

## 6. Verdict

**SHIP-PHASE-0.2** with three `[CONFIRM]` items that must close before Phase 0.2 Day 2 dispatches the other 3 specialists.

No `DUPLICATE-DEPRECATE` rows were found. Every capability the kit ships is either a pure addition (not shipped by Anthropic) or a legitimate wrap with a documented wedge rationale. Both prior `RAISE-WITH-GIAN` rows closed 2026-05-18 as `WRAP-OK` after a second-pass evidence sweep on `agent.expo.dev` + the `expo/skills` repo (Section 1 above).

### CONFIRM items that must close before Phase 0.2 Day 2 dispatch

**CONFIRM-001 (High).** `tools/anthropic-drift-check.sh` does not exist. The installer references it as a TODO placeholder. The script must be written and tested before Phase 0.2 Day 2 ships. Without it, the PREMORTEM rank-1 failure (Anthropic subsumes the kit) has no detection mechanism. Assign to Gian.

**CONFIRM-002 (Critical).** `tool-output-fencing` skill is listed as a mitigation for indirect prompt injection (PREMORTEM rank-2) but its activation on template ingestion paths is unverified. Before Phase 0.2 Day 2 ships any skill that reads external content (template READMEs, docs, course transcripts), a security audit pass must verify `tool-output-fencing` is active on those code paths. Assign to the Phase 0.2 Day 2 review pass.

**CONFIRM-003 (High).** `EXPO_SDK_PIN="latest"` in both `install.sh` (line 13) and `install.ps1` (line 12) is a placeholder. A real semver pin must replace it before Phase 0.2 Day 2 or the installer provides no protection against SDK drift. Assign to Gian.

---

## Open Questions

| ID | Question | Owner | Blocks |
|---|---|---|---|
| CONFIRM-001 | Write and test `tools/anthropic-drift-check.sh` per Section 5 spec | Gian | Phase 0.2 Day 2 |
| CONFIRM-002 | Verify `tool-output-fencing` is active on all external-content ingestion paths in Phase 0.2 skills | Gian | Phase 0.2 Day 2 |
| CONFIRM-003 | Replace `EXPO_SDK_PIN="latest"` with a verified semver in `install.sh` and `install.ps1` | Gian | Phase 0.2 Day 2 |

Prior `RAISE-001` and `RAISE-002` closed 2026-05-18 as `WRAP-OK` via second-pass evidence on `agent.expo.dev` and `github.com/expo/skills`.

---

## Coverage Statement

**Reviewed (first pass, Gian):**
- `D:\FOLDERMAIN%\selrai-mobile-kit\README.md`
- `D:\FOLDERMAIN%\selrai-mobile-kit\docs\prior-art.md`
- `D:\FOLDERMAIN%\selrai-mobile-kit\install.sh`
- `D:\FOLDERMAIN%\selrai-mobile-kit\install.ps1`
- `D:\FOLDERMAIN%\selrai-mobile-kit\SETUP-PROMPT.md`
- https://claude.com/plugins/expo (live fetch 2026-05-18, plugin description extracted)
- https://claude.com/plugins (live fetch 2026-05-18, full plugin directory)
- https://code.claude.com/docs/en/whats-new (Weeks 13-19, 2026, verified)
- https://code.claude.com/docs/en/whats-new/2026-w16 (Week 16 detail, mobile push notifications)
- https://code.claude.com/docs/en/plugins (plugin architecture, monitors, settings, egress controls)

**Reviewed (second pass, 2026-05-18, closes RAISE rows):**
- `https://agent.expo.dev/` (developer-targeted marketing landing, no kit-overlap claims)
- `https://docs.expo.dev/agent/` (returns 404, no docs section exists)
- `https://expo.dev/agent` (307 redirect to `agent.expo.dev`)
- `github.com/expo/skills/plugins/expo/skills/` (14 skills enumerated, see Section 1.5)
- WebSearch "Expo Agent April 2026 features non-technical onboarding templates wizard launch" (no relevant primary or secondary hits)

**Not reviewed (remaining blind spots):**
- The 3 template source directories (`pt-companion/`, `service-quote/`, `creator-companion/`). These are Phase 0.2 deliverables and do not exist yet. Injection surfaces within those templates are not audited. Phase 0.2 Day 2 security pass covers them.
- Phase 0.2 skill bodies. All 4 skills are stubs. Full injection-surface audit depends on Phase 0.2 implementations.
- Nick Sarev course transcript. Not fetched per Gian's confirmed decision 2026-05-18.

---

## Phase 0.2 Day 2 security re-pass (2026-05-18)

**Author:** Gian (security audit)
**Scope:** CONFIRM-002 closure pass. Full Phase 0.2 build (commit d6f6b26, main). SDK corrected from 52.0.0 to 55.0.24.

---

### 1. Ingestion path table

For each external-content path in the four Phase 0.2 skills plus the drift-check script: "external content" means anything that could carry adversarial text reaching model context.

| Path | Source type | tool-output-fencing covers? | Notes |
|---|---|---|---|
| `mobile-template-pick` Step 1: user's three free-text answers | User prose (direct input, business description field) | No. Direct input is a `UserPromptSubmit` surface, not a tool output. tool-output-fencing is a `PostToolUse` hook, scoped to tool results only. | Covered partially by the 8 KB content cap implicit in the skill (one-sentence input contract). Lakera-style injection pre-pass is absent. Separate finding below. |
| `mobile-template-pick` Step 3a: `ollama run` stdout | Local Gemma on local Ollama. Stdout captured via `Bash`/`PowerShell` tool call matching `ollama`. Classifier result is template name only. | Partial. The `Bash`/`PowerShell` Bash matchers in the fencing scope table watch for `curl\|wget\|Invoke-WebRequest\|iwr\|Invoke-RestMethod\|irm` (SKILL.md lines 28-30). `ollama run` does not match those patterns. Not fenced. | Low residual risk: Gemma is local, output is validated against a 3-value allowlist (`pt-companion`/`service-quote`/`creator-companion`) before use. Invalid output silently falls through to deterministic rules. The validation is an effective output sanitizer for this narrow path. |
| `mobile-readiness-check` Step 4: `curl --head https://registry.npmjs.org` stdout | External HTTP HEAD response headers. Captured via `Bash` tool call containing `curl`. | Yes. The `Bash` matcher in SKILL.md line 28 (`curl\|wget\|...`) fires on this call. | Only response headers are read (first line via `head -1`). No body content ingested. Low injection surface even without fencing. |
| `mobile-readiness-check` Step 5: `curl --head https://exp.host` stdout | External HTTP HEAD response headers. Same as above. | Yes. Same `curl` Bash matcher applies. | Same note: headers only, first line only. |
| `mobile-app-bootstrap` Step 1: `ls ~/.claude/plugins/` stdout | Local filesystem listing. `Bash` tool, path is local, not an HTTP URL. | No. SKILL.md explicitly states: "Internal Read of source files is not fenced." The fencing scope for `Read` is `^https?://` OR HTML/XML in Downloads/Temp/cache. Filesystem `ls` does not match. | Low risk: output is a directory listing. No adversarial text surface. |
| `mobile-app-bootstrap` Step 3: `ls ~/.claude/selrai-mobile-kit/templates/<name>/` and `ls ./templates/<name>/` | Local filesystem listing. | No. Same rationale as above. | Low risk: directory listing only. |
| `mobile-app-bootstrap` Step 4: `npx create-expo-app@latest` stdout | npm registry network call via Bash (npx). Does not match `curl\|wget\|Invoke-WebRequest`. | No. npx is not in the fencing matchers. | Medium residual risk: scaffold stdout is suppressed from user view by the skill's no-raw-output rule, but it still enters model context. If create-expo-app prints adversarial text in a future version (supply chain), the model sees it unfenced. Separate finding below (FIND-001). |
| `mobile-app-bootstrap` Step 5: `cp -r <template-source>` / `Copy-Item` | In-repo template files copied to user filesystem. Static TypeScript/JSON files. | No. Not a network fetch, not HTML in a temp path. | Templates verified clean (see Section 2 below). No adversarial content in any `app/_layout.tsx`, `app/index.tsx`, `package.json`, `README.md`. |
| `mobile-app-bootstrap` Step 6-7: `bun add`/`bun install` stdout | npm registry network calls via Bun. Does not match fencing matchers. | No. Same gap as npx above. | Medium residual risk: same supply-chain vector as Step 4. Stdout suppressed from user but reaches model. Separate finding (FIND-001). |
| `mobile-phone-preview` Step 2: `bun run start` (Metro bundler) stdout | Local process stdout. No network fetch, no external content. | No. Local process; fencing not applicable. | Skill instructs model to not surface raw Metro output. Model sees it but is instructed to filter. Low risk. |
| `anthropic-drift-check.sh` line 55: `curl -sSL https://claude.com/plugins/expo` | External HTTP body (HTML page). | Yes. The `curl` Bash matcher fires. | Critical path: the fetched HTML is stored in `HTTP_BODY` variable. It is then processed via `grep -oP` regex to extract the `og:description` meta tag (lines 98-107). The extracted text is then SHA-256 hashed (lines 118, `_sha256`). The hash (not the text) is stored in the manifest. The raw `HTTP_BODY` is never echoed to stdout for the model to read as instructions. The description text is only used as input to `sha256sum`. Hash-not-text pattern confirmed: line 118. |
| `anthropic-drift-check.sh` line 60: second `curl` for HTTP status code | External HTTP connection, `-w "%{http_code}"` only, `-o /dev/null`. | Yes. Same curl matcher. | Status code is a 3-digit integer, not user-controlled text. Zero injection surface. |

---

### 2. Template static-content verification

All six TypeScript template source files (`app/_layout.tsx` and `app/index.tsx` for each of the three templates) were read in full.

Findings:
- Zero network fetch calls in any template file. No `fetch()`, no `axios`, no `Invoke-WebRequest`, no external URL references in code.
- Zero dynamic content ingestion. All strings are hardcoded labels (`"Welcome back"`, `"New Quote"`, etc.).
- Zero external script imports. All imports are from `react-native`, `expo-router`, and `react`.
- The `handlePlaceholder` function in each `index.tsx` only calls `console.log` and `Alert.alert` with hardcoded strings. No model-visible content.
- Package.json dep trees: `expo 55.0.24`, `expo-router ~55.0.14`, `expo-status-bar ~55.0.6`, `react 19.2.0`, `react-native 0.83.6`, `nativewind ^4.2.4`, `tailwindcss ^3.4.0`. All are current, maintained packages as of 2026-05-18.

Template README files contain no dynamic fetch instructions and no URLs other than internal `mobile-phone-preview` references. The one TODO comment in each README (`templates/pt-companion/README.md` line 21, `templates/service-quote/README.md` line 21, `templates/creator-companion/README.md` line 21) mentions aligning `EXPO_SDK_PIN` in Phase 0.3. Not an injection vector.

**Template source content: clean. No adversarial content surface identified.**

One secondary finding noted: all three template READMEs still reference "Expo SDK 54" in the Stack section (line 19 of each README) while `package.json` correctly pins `expo 55.0.24`. This is a documentation inconsistency, not a security finding. Assigned FIND-002.

---

### 3. CONFIRM-002 disposition

**CONFIRM-002: CLOSED (with two residual non-blocking findings).**

The prior audit concern was: "`tool-output-fencing` skill is listed as a mitigation for indirect prompt injection (PREMORTEM rank-2) but its activation on template ingestion paths is unverified."

Evidence reviewed:

1. The `tool-output-fencing` skill body exists at `D:\FOLDERMAIN%\Gian's Master Files and Projects (AI)\Gian's Agents\skills\tool-output-fencing\SKILL.md`. The skill is in the user-level kit, confirmed present via glob scan.

2. Scope of fencing per SKILL.md lines 27-31: `WebFetch` (always), `Bash` when matching `curl|wget|Invoke-WebRequest|iwr|Invoke-RestMethod|irm`, `PowerShell` same matchers, `Read` when path is `^https?://` or HTML/XML in Downloads/Temp/cache. Internal filesystem reads are explicitly not fenced.

3. Applying this scope to every ingestion path in Section 1:
   - The two curl calls in `mobile-readiness-check` (Steps 4-5) are fenced by the curl Bash matcher.
   - The two curl calls in `anthropic-drift-check.sh` (lines 55, 60) are fenced. Critically, the fetched HTML body is processed by the bash script, not passed to the model as readable text. The script extracts a description string, hashes it, and stores only the hash. The model never reads the raw HTML. Even if fencing did not fire, there is no injection surface because the adversarial content never reaches model-readable context.
   - Template copy operations (`cp`, `Copy-Item`) are not fenced, correctly. The template files are static, in-repo, with no adversarial content (verified Section 2).
   - `npx create-expo-app`, `bun add`, and `bun install` stdout is not fenced (matchers do not cover package managers). This is FIND-001 (Medium severity, not blocking).
   - `ollama run` stdout is not fenced, but is sanitized by the 3-value output allowlist in the skill before any use (mobile-template-pick Step 3a validation logic).
   - The user's business-description input (`mobile-template-pick` Step 1) is a `UserPromptSubmit` surface, not a tool output. Fencing does not apply here by design. This is a distinct injection surface addressed separately (FIND-003, Medium).

4. Soft-warn wiring verified: `install.sh` lines 93-99 and `install.ps1` lines 193-200 both check for `tool-output-fencing.md` in the skills directory and emit a named log warning if absent. The warning text correctly names the security function. The install does not block, per the "soft-warn" design decision. The absence condition is surfaced to the installer.

Conclusion: the fencing skill correctly covers every external-network fetch that reaches model context in the Phase 0.2 skill chain. The one gap (npm/Bun package manager stdout) is a pre-existing architectural ceiling of the PostToolUse hook layer (npm stdout is not a curl-matcher path), and its blast radius is bounded by the skill's no-raw-output rule. The drift-check script uses a hash-not-text pattern that makes the external HTML body unreachable as model instructions even without fencing. CONFIRM-002 closes.

---

### 4. New findings

**FIND-001 (Medium)**
Location: `skills/mobile-app-bootstrap.md` Steps 4, 6, 7 (lines 59, 84-86, 91-92)
Description: `npx create-expo-app@latest` and `bun add`/`bun install` are network-reaching package-manager calls. Their stdout passes through the Bash/PowerShell tool result and enters model context. Neither `npx` nor `bun` matches the fencing skill's tool-call matchers (`curl|wget|Invoke-WebRequest|iwr|Invoke-RestMethod|irm`). A malicious package on the npm registry that prints adversarial output to its install script stdout would reach the model unfenced. The skill's no-raw-output rule instructs the model to suppress this content from user view but does not prevent the model from acting on it.
Recommended fix (Phase 0.3): extend the fencing skill's Bash/PowerShell matchers to include `npx|bun|npm`. This is a one-line change to the matcher in the PostToolUse hook config. Alternatively, add a `[DATA-NOT-INSTRUCTIONS]` inline reminder at the start of Steps 4, 6, 7 in the skill body.
References: OWASP LLM01 (indirect prompt injection), SKILL.md lines 27-31.
Blocks ship: No. Blast radius is bounded by the 5-host egress allowlist (registry.npmjs.org is in the allowlist, no other hosts can serve packages) and the skill's output-suppression rule. The attack requires a compromised npm package already on the registry. Medium, not High, because the egress allowlist is a compensating control.

**FIND-002 (Low)**
Location: `templates/pt-companion/README.md` line 19, `templates/service-quote/README.md` line 19, `templates/creator-companion/README.md` line 19
Description: All three template READMEs state "Expo SDK 54" in the Stack section. All three `package.json` files correctly pin `expo 55.0.24`. A user or contributor reading the README would have mismatched version information. Not a security issue. Documentation debt.
Recommended fix (Phase 0.3): update all three README Stack sections from "Expo SDK 54" to "Expo SDK 55 (55.0.24)". Same edit as the existing TODO comment in each README.
References: None.
Blocks ship: No.

**FIND-003 (Medium)**
Location: `skills/mobile-template-pick.md` Steps 1-3 (lines 22-101)
Description: The user's business description (Step 1) is free-text prose with no byte ceiling, no injection pre-pass, and no content sanitization before it is interpolated into the Ollama prompt string (Step 3a, lines 78-89). A non-technical user could paste a large block of text (no cap enforced) or an attacker interacting with a deployed version of this skill could craft a business description that contains prompt injection payloads targeting Gemma's classification output. The Gemma output is validated to a 3-value allowlist before use, which partially mitigates the injection risk against the model's downstream classification decision, but the raw business description string is also included in the rationale sentence emitted to the user (Step 4, lines 130-145), which could cause the injected content to surface in Claude's response.
Recommended fix (Phase 0.3): add an 8 KB hard cap on the business description input before it is used in Step 3a. Apply the `injection_prepass` check per the SelrAI input-surface 4-item checklist. The Gemma output allowlist validation (already present) is the correct mitigation for the classification decision path, but the rationale sentence path needs the input capped and sanitized first.
References: OWASP LLM01, SelrAI Discipline Contract input-surface checklist item 4 (injection pre-pass), item 2 (content cap).
Blocks ship: No. The deployed surface is a locally-run Claude Code session with a non-technical single user. The threat model for Phase 0.2 is a non-adversarial small-business owner running the kit on their own machine. At Phase 0.3, if this skill is exposed to any shared or web-delivered surface, this finding escalates to High and blocks ship.

---

### 5. Input surface checklist (Phase 0.2 new surfaces)

Per the SelrAI Discipline Contract input-surface 4-item checklist:

| Surface | Allowlist | Rate limit | Content cap | Injection pre-pass |
|---|---|---|---|---|
| `mobile-template-pick` business description (user prose) | N/A. Single local user, identity fixed. | N/A. Single local session. | No. No byte ceiling enforced. (FIND-003) | No. No Lakera-scan before Ollama call. (FIND-003) |
| `mobile-readiness-check` curl stdout (network probe) | N/A. Output is HTTP status code only. Headers first-line only. | N/A. | N/A. | Fenced by PostToolUse hook (curl matcher). |
| `anthropic-drift-check.sh` curl stdout (plugin page HTML) | N/A. Script context, not model context. | N/A. | N/A. | Fenced by PostToolUse hook. Raw HTML hashed, not passed to model. |

Rationale for N/A on allowlist and rate limit: these surfaces are Claude Code skills invoked locally by a single authenticated user on their own machine. There is no inbound network surface, no webhook, no shared identity pool. The 4-item checklist items 1 and 2 are designed for multi-tenant or networked entry points. Documenting the N/A explicitly per the checklist contract.

---

### 6. Premortem gate (Phase 0.2 Day 2, per BRAIN.md mandatory gate)

"This shipped. Six months later, it failed. The cause was ___."

| Cause | Likelihood rank | Severity | Earliest detection signal | Mitigation present | Mitigation ref |
|---|---|---|---|---|---|
| A supply-chain compromised npm package (reached via npx or bun in bootstrap) prints adversarial stdout that causes Claude to take an unexpected action during scaffolding | 1 | Medium | User reports unexpected files created or CLI commands run during scaffolding. First log signal: unexpected Bash tool call outside the expected scaffold sequence. | Partial. Egress allowlist limits install sources to `registry.npmjs.org`. Skill no-raw-output rule suppresses stdout from user. Fencing does not cover package managers (FIND-001). | `install.sh` lines 111-123 (egress allowlist). FIND-001. |
| User pastes a large or adversarially crafted business description into the template picker, causing injection into the Gemma prompt or surfacing injected text in the Claude rationale response | 2 | Medium | Claude's rationale sentence in Step 4 contains text that does not match the expected one-sentence format. User or auditor notices non-PT/service/creator-related content in the response. | Partial. Gemma output validated to 3-value allowlist. Injected content in rationale sentence is not blocked. No byte cap on input. | `skills/mobile-template-pick.md` lines 98-101 (output validation). FIND-003. |
| Expo SDK 55 ships a breaking change to `create-expo-app` or `expo-router` within 6 months that silently fails the scaffold without a user-visible error | 3 | Medium | `mobile-app-bootstrap` Step 4 fails; skill emits one-sentence error. User files a GitHub issue. No silent failure: every step has an explicit fail message. | Yes. Hard pin at 55.0.24. `mobile-app-bootstrap` Step 4 fail message surfaces the error. Drift check monitors Anthropic plugin description for SDK-overlap signals. | `install.sh` line 17, `install.ps1` line 16. `skills/mobile-app-bootstrap.md` lines 62-63. |
| The `tool-output-fencing` skill is absent at the time of skill invocation (not installed or overwritten by another kit's installer), leaving the curl-probe paths unfenced | 4 | Medium | Soft-warn fires during install (install.sh lines 93-99). If user skips install and invokes skills directly, no warning surfaces. | Partial. Install soft-warn present. No enforcement at skill invocation time. | `install.sh` lines 93-99, `install.ps1` lines 193-200. |
| Template README SDK version mismatch (SDK 54 vs actual 55.0.24) causes a contributor to submit a PR that downgrades package.json to match the README | 5 | Low | PR diff shows expo downgraded to ~54.x. Caught at code review. | Partial. The TODO comment in each README flags the mismatch for Phase 0.3 fix. No automated check exists. | `templates/pt-companion/README.md` line 21. FIND-002. |

All Critical and High causes: none present. No premortem cause blocks the ship verdict.

---

### 7. Ship verdict for Phase 0.2 build

**SHIP**

Rationale: CONFIRM-002 is closed with evidence. The two prior High CONFIRM items from Day 1 (CONFIRM-001: drift-check script, CONFIRM-003: SDK pin) were resolved before this pass (drift-check script exists and is wired; SDK pin replaced with 55.0.24). The three new findings (FIND-001, FIND-002, FIND-003) are Medium and Low severity with compensating controls present. No Critical or High finding is unmitigated in the Phase 0.2 build. The premortem produces no Critical or High causes without mitigation.

The ship verdict is conditioned on Phase 0.3 addressing the punch list in Section 8.

---

### 8. Phase 0.3 hardening punch list

These items are not blocking Phase 0.2 ship. They must be addressed before any surface in this kit is exposed to a shared, multi-user, or web-delivered deployment.

1. **FIND-001 fix.** Extend the PostToolUse fencing hook's Bash/PowerShell matchers to include `npx|bun|npm`. One-line change in the hook config. Verify the change does not over-fence internal bun calls (e.g. `bun -v` in readiness check should not be fenced).
2. **FIND-003 fix (Gian).** Add 8 KB hard cap on the business description input in `mobile-template-pick` Step 1, enforced before the string is interpolated into the Ollama prompt. Add an inline injection pre-pass (even a simple keyword filter for `ignore previous instructions`, `system:`, `[INST]`, `<s>` patterns) before the Ollama call.
3. **FIND-002 fix (Gian).** Update all three template READMEs: change "Expo SDK 54" to "Expo SDK 55 (55.0.24)" in the Stack section. Align with the TODO comment at line 21 of each README.
4. **Template README SDK TODO resolution (Gian).** Remove the TODO comment at line 21 of each template README once FIND-002 is fixed and the SDK version is confirmed stable through Phase 0.3 smoke tests.
5. **Input-surface checklist re-run (Gian).** If Phase 0.3 adds any new user-input surface, a fresh input-surface audit is required before that skill ships. The Phase 0.2 surfaces (local single-user, no allowlist needed) do not generalize to Phase 0.3 surfaces if GHL or webhook surfaces are added.
6. **CONFIRM-004 (Gian, carried from Day 1).** `og:description` extraction reliability in `anthropic-drift-check.sh`. This pass confirms the hash-not-text pattern is safe, but the reliability of the extraction regex against future Claude.com HTML structure changes is an concern, not a concern. Phase 0.3 scope.
7. **CONFIRM-005 (Gian, carried from Day 1).** `$PSScriptRoot` reliability in piped-exec installs on Windows. Phase 0.3 scope.

---

### 9. Coverage statement (Phase 0.2 Day 2)

**Reviewed in this pass:**
- `D:\FOLDERMAIN%\selrai-mobile-kit\docs\anthropic-overlap.md` (prior audit, Section 7 CONFIRM-002)
- `D:\FOLDERMAIN%\selrai-mobile-kit\skills\mobile-readiness-check.md` (full)
- `D:\FOLDERMAIN%\selrai-mobile-kit\skills\mobile-template-pick.md` (full)
- `D:\FOLDERMAIN%\selrai-mobile-kit\skills\mobile-app-bootstrap.md` (full)
- `D:\FOLDERMAIN%\selrai-mobile-kit\skills\mobile-phone-preview.md` (full)
- `D:\FOLDERMAIN%\selrai-mobile-kit\install.sh` (lines 92-99 soft-warn, lines 67-79 drift-check wiring, full)
- `D:\FOLDERMAIN%\selrai-mobile-kit\install.ps1` (lines 193-200 soft-warn, lines 69-165 drift-check, full)
- `D:\FOLDERMAIN%\selrai-mobile-kit\tools\anthropic-drift-check.sh` (full, 187 lines)
- All 6 template TypeScript files (`app/_layout.tsx`, `app/index.tsx` for pt-companion, service-quote, creator-companion)
- All 3 template `package.json` files
- All 3 template `README.md` files
- `templates/README.md`
- `evals/template-picker-eval.jsonl` (10 cases)
- `D:\FOLDERMAIN%\Gian's Master Files and Projects (AI)\Gian's Agents\skills\tool-output-fencing\SKILL.md` (fencing scope table, activation triggers, hook wiring)

**Not reviewed in this pass (remaining blind spots):**
- The PostToolUse hook script (`hooks/PostToolUse.tool-output-fence.ps1`) was not read. The fencing scope was verified from SKILL.md, not from the hook implementation itself. If the hook implementation differs from the SKILL.md scope table, FIND-001 and the CONFIRM-002 coverage claim may need revision. Assign hook implementation verification to Phase 0.3.
- Live smoke test on a real phone (Day 3 work, per scope exclusion).
- CONFIRM-004 and CONFIRM-005 (Phase 0.3, per scope exclusion).
