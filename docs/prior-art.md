# Prior Art and Wedge Analysis

**Date:** 2026-05-18
**Author:** Gian Carlo Carino (Gian)
**Status:** Phase 0.1 ship-locked

Mandatory crawl per memory rule `repo-crawl-before-rd-kit`. Captures the landscape at kit-design time so future maintainers know what we evaluated, what we chose to wrap vs ignore vs reject.

## 1. SelrAI internal kit inventory (gh repo list selrai-company)

Top-30 most-recently-pushed repos checked 2026-05-18. **No existing mobile / Expo / Sarev kit in `selrai-company`.** Clean slate.

Related-but-distinct kits already shipped:

| Repo | Why not this | Why we are still separate |
|---|---|---|
| `claude-workshop-kit` | Flagship general-purpose AI assistant on the user's laptop. Persistent memory + 120+ skills + browser automation. Not mobile. | Different surface, different audience setup, different install path. |
| `pt-industry-pack-workshop` | Vertical pack for solo personal trainers. PT Brain, 25 connectors, 15 cron agents. Includes voice agent, content factory, GHL sub-account. | Industry-vertical bundle, not a mobile-app builder. Our PT template feeds the same vertical but is the mobile companion, not the back-of-house stack. |
| `selrai-gateway` / `claude-os` | Hermes-equivalent autonomous agent on Claude Agent SDK. Subscription-billed multi-platform listener. | Server-side agent runtime, not a phone-app authoring kit. |
| `wnd-fire-dashboard`, `onq-quote-runner` | Custom client work. React + Express dashboards. | Not generalised, not non-technical-targeted. |

**Verdict:** No duplication risk inside `selrai-company`. Standalone repo is the right call (per memory `standalone-repo-per-feature`).

## 2. Anthropic-shipped overlap

**Critical finding driving the kit's wedge.**

- **Anthropic ships an official `expo` plugin** at https://claude.com/plugins/expo. Install base approximately 5,739 at crawl time. Covers the full Expo dev lifecycle: scaffold, run, iterate, deploy via Anthropic's standard plugin install path.
- **Expo Agent launched April 2026** ($45M Series B). Native vibe-coding integration into the Expo CLI surface.

**Implication:** The developer-facing path is solved by Anthropic + Expo themselves. Rebuilding it inside SelrAI would violate Harvey's 2026-05-18 rule (do not rebuild Anthropic-shipped features as skills).

**Our wedge:** Wrap the official plugin with a non-technical entry path. Specifically:

1. **Pre-install gate.** A `mobile-readiness-check` skill that detects Node, Bun, free disk, phone-pair compatibility. Returns a single sentence on success or a one-step fix on failure. No raw error logs in front of a non-technical user.
2. **3 vertical templates** aligned to V4.1.2 sellable shapes (`pt-companion`, `service-quote`, `creator-companion`). The official plugin scaffolds a blank Expo app. Our templates ship pre-wired domain logic.
3. **Phone-as-simulator default.** Expo Go on the user's own phone via QR scan. The official plugin defaults assume a developer audience with Xcode and Android Studio installed. We invert that assumption.
4. **Local-Gemma template picker.** A user describes their business in plain English. The local LLM (no API cost) picks one of the 3 templates and scaffolds it. The official plugin has no opinionated template router.
5. **Egress allowlist** in `.claude/settings.json` baked into the installer. Restricts the kit's Claude Code session to npm registry + Expo CDN. The official plugin does not impose this.

## 3. Community-built mobile-Claude-Code stacks

Surveyed in case any are worth absorbing or learning anti-patterns from.

- `senaiverse/claude-code-reactnative-expo-agent-system` (GitHub, community). 7-agent parallel stack. **Anti-pattern.** Parallel re-implementation of what Anthropic now ships officially. Studied for shape but not copied.
- Various Medium / dev.to posts on "Claude Code + Expo". Mostly walkthroughs of the official plugin, not extension kits. Confirms the dev-facing entry is well-trodden, the non-technical entry is not.

## 4. Nick Sarev's 4-hour course

- Source: https://www.youtube.com/watch?v=BMMcmmnjrM8
- Length: approximately 4 hours
- Audience as presented: vibe-coders and Claude Code early adopters who want a mobile output. Tone is hands-on, assumes Claude Code already installed.
- Course structure (inferred from chapter pattern, transcript fetch deferred to Phase 0.2 Day 1):
  1. Setup and tooling
  2. First screen and navigation
  3. State and persistence
  4. Backend wiring
  5. Local build and phone preview
- Module mapping (planned, validate in Phase 0.2):
  - Chapters 1 to 3 condense into the 3 SelrAI skills (`mobile-readiness-check`, `mobile-app-bootstrap`, `mobile-phone-preview`)
  - Chapters 4 to 5 become reference docs that point to Anthropic's official `expo` plugin commands plus our 3 templates' pre-wired stubs

**Licensing note:** Per Gian's confirmed decision 2026-05-18, the transcript stays an external link (YouTube URL + timestamps in `docs/sarev-course-map.md`). No verbatim transcript committed.

## 5. Stack selection rationale

| Choice | Rejected alternative | Reason |
|---|---|---|
| Expo + RN + Hermes | Bare React Native CLI | No Expo Go + QR flow, harder non-technical install. |
| Expo + RN + Hermes | Capacitor | Web-shell on native, weaker native feel, conflicts with "scan QR with Expo Go" promise. |
| Expo + RN + Hermes | Tauri Mobile | Immature on iOS at 2026-05. Reject. |
| Expo SDK hard-pin | Latest-minor or always-latest | Predictability for non-technical users. Per Gian's confirmed decision 2026-05-18. Installer prints upgrade prompt when drift detected. |
| Bun | npm / yarn / pnpm | Selr default per CLAUDE.md, fastest install on Win11 + macOS. |
| NativeWind | StyleSheet API / Restyle | Tailwind familiarity transfers from web; lower learning curve for the non-technical workshop attendee. |
| Local Gemma on Ollama for template picker | Claude API | CLAUDE.md hard rule #3 (use local infra first). Template picker is a cheap classification task, fits local-LLM cost target. |

## 6. Failure modes mapped to mitigations

Linked to PREMORTEM in Phase 0.1 brief. Summary here for grep-ability:

| Failure | Mitigation owner | Status |
|---|---|---|
| Anthropic ships a "mobile starter" wizard that subsumes the kit | Gian | `tools/anthropic-drift-check.sh`, per-install only per Gian 2026-05-18, lands Phase 0.2 Day 2 |
| Expo Go device-pair friction on different wifi / corporate firewall | Gian | `mobile-readiness-check` hotspot-fallback path, lands Phase 0.2 Day 2 |
| Indirect prompt injection via fetched template or transcript | Gian | Templates ship in-repo, `tool-output-fencing` skill on transcript ingestion, egress allowlist in installer |
| Expo SDK drift between install and first build | Gian | Hard SDK pin per Gian 2026-05-18, installer prints drift warning |
| Kit confused with `claude-workshop-kit` or `pt-industry-pack-workshop` | | Value-led README (this scaffold), R&D-chat announcement, `selr-kit-index` YAML entry Phase 0.2 Day 3 |

## 7. References

- Notion task: https://www.notion.so/364b97b5991f8171a512ef88a4d318b2
- 18 May meeting summary: https://www.notion.so/364b97b5991f81febe99ebb50c24aa10
- 18 May R&D log: https://www.notion.so/364b97b5991f815cb25ce70b31a1c211
- Anthropic Expo plugin: https://claude.com/plugins/expo
- Sarev course: https://www.youtube.com/watch?v=BMMcmmnjrM8
- BRAIN.md sections referenced: §3 (V4.1.2 spine), §5 (hard rules), §7 (this project's role), §8 (R&D pipeline), §9 (public kits)
