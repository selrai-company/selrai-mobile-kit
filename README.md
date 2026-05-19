# selrai-mobile-kit

**Ship a working mobile app to your own phone in a half-day. No Xcode. No Android Studio.**

A Claude Code kit for **non-technical** Skool Premium members and Architecture-tier clients who want a mobile surface for their own business. No prior mobile dev experience required.

## What you get

- **3 vertical templates** ready to scan-and-run on your phone:
  - `pt-companion` (personal trainer workout + client check-ins)
  - `service-quote` (on-site quote, sign, pay, book)
  - `creator-companion` (content prompts, schedule, GHL passthrough)
- **Phone-as-simulator** default. Install Expo Go on your phone, scan a QR code, the app runs.
- **Local-Gemma template picker.** Describe your business in plain English, get a starter template + scaffolded screens.
- **One-command install.** Idempotent. Re-runs are safe.

## What this is not

- Not a "build me an app store-ready release" kit. App-store testing is out of scope. Local builds and phone preview only.
- Not a generic mobile dev framework. Three vertical templates, opinionated stack, value over flexibility.
- Not a fork of Anthropic's official Expo plugin. The kit **wraps** the official plugin with a non-technical entry path.

## Install

```bash
# macOS / Linux
bash <(curl -sSL https://raw.githubusercontent.com/selrai-company/selrai-mobile-kit/main/install.sh)
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/selrai-company/selrai-mobile-kit/main/install.ps1 | iex
```

After install, open Claude Code and run `/mobile-readiness-check`. The kit walks you the rest of the way.

## Uninstall

Clean teardown is idempotent. Removes only what the installer created (4 skill files, kit state dir, `selrai_mobile_kit` key in `settings.json`). Other user keys, other skills, and scaffolded projects on your filesystem are untouched.

```bash
# macOS / Linux
bash uninstall.sh           # interactive
bash uninstall.sh --yes     # non-interactive
bash uninstall.sh --dry-run # audit only, no changes
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File uninstall.ps1
powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Yes
powershell -ExecutionPolicy Bypass -File uninstall.ps1 -DryRun
```

Smoke-tested at `tests/uninstall_smoke.sh` (20/20 assertions PASS on Win11 + Bun 1.3.14, including sentinel-key preservation in `settings.json`).

## Status

**Phase 0.1 ship-locked 2026-05-18.** Design + scaffold + prior-art doc landed.
**Phase 0.2 in flight.** Skill implementations and 3 templates land over the next 2 days.
**Phase 0.3 (Harvey curation)** decides workshop module + Skool drop placement.

See [docs/prior-art.md](docs/prior-art.md) for the wedge analysis (why we wrap the official Anthropic Expo plugin instead of rebuilding it).

## Stack

- Anthropic [`expo` plugin](https://claude.com/plugins/expo) (official, the dev-lifecycle base)
- Expo SDK (hard-pinned, see install.sh)
- React Native + Hermes
- Expo Router (file-based routing)
- NativeWind (Tailwind for React Native)
- Bun (package manager + runtime)
- Local Gemma 4 on Ollama (for the in-kit template picker, not the build agent)

## Audience

- Skool Premium members shipping a mobile surface for their own business
- Architecture-tier clients who want a mobile companion to a SelrAI build
- Workshop attendees on the half-day mobile track

If you are a developer already comfortable with React Native, you do not need this kit. Use Anthropic's `expo` plugin directly.

## License

Private to selrai-company. Distribution per the V4.1.2 R&D repo policy.
