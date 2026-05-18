# service-quote

**What it is:** A mobile home screen for on-site service businesses. Entry points for creating a new quote and viewing today's job list.

**Who it is for:** Tradies, cleaners, landscapers, and any on-site service provider who wants to quote and track jobs from their phone.

**Current state:** Phase 0.2 scaffold. 1 working home screen. Both buttons show a placeholder alert. Phase 0.3 wires them to your job list and quoting workflow.

## Run it

```bash
cd service-quote && bun install && bun run start
```

Then scan the QR code with Expo Go on your phone. See `/mobile-phone-preview` if you need a step-by-step walk-through.

## Stack

Expo SDK 55 (pinned to 55.0.24) + React Native 0.83.6 + React 19.2 + Expo Router 55.0.x + NativeWind 4.2.x. Bun as the package manager.
