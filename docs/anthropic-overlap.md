# Anthropic Overlap Audit

**Document type:** Phase 0.2 Day 1 security deliverable
**Author:** security-engineer (SelrAI agent, dispatched 2026-05-18)
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

**CONFIRM-001 (High).** `tools/anthropic-drift-check.sh` does not exist. The installer references it as a TODO placeholder. The script must be written and tested before Phase 0.2 Day 2 ships. Without it, the PREMORTEM rank-1 failure (Anthropic subsumes the kit) has no detection mechanism. Assign to infra-engineer.

**CONFIRM-002 (Critical).** `tool-output-fencing` skill is listed as a mitigation for indirect prompt injection (PREMORTEM rank-2) but its activation on template ingestion paths is unverified. Before Phase 0.2 Day 2 ships any skill that reads external content (template READMEs, docs, course transcripts), a security-engineer pass must verify `tool-output-fencing` is active on those code paths. Assign to security-engineer (this agent, Phase 0.2 Day 2 review pass).

**CONFIRM-003 (High).** `EXPO_SDK_PIN="latest"` in both `install.sh` (line 13) and `install.ps1` (line 12) is a placeholder. A real semver pin must replace it before Phase 0.2 Day 2 or the installer provides no protection against SDK drift. Assign to infra-engineer.

---

## Open Questions

| ID | Question | Owner | Blocks |
|---|---|---|---|
| CONFIRM-001 | Write and test `tools/anthropic-drift-check.sh` per Section 5 spec | infra-engineer | Phase 0.2 Day 2 |
| CONFIRM-002 | Verify `tool-output-fencing` is active on all external-content ingestion paths in Phase 0.2 skills | security-engineer | Phase 0.2 Day 2 |
| CONFIRM-003 | Replace `EXPO_SDK_PIN="latest"` with a verified semver in `install.sh` and `install.ps1` | infra-engineer | Phase 0.2 Day 2 |

Prior `RAISE-001` and `RAISE-002` closed 2026-05-18 as `WRAP-OK` via second-pass evidence on `agent.expo.dev` and `github.com/expo/skills`.

---

## Coverage Statement

**Reviewed (first pass, security-engineer):**
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
