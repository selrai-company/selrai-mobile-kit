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

Expo SDK 54 (pinned to 54.0.34) + React Native 0.81.5 + React 19.1 + Expo Router 5.1.x + NativeWind 4.2.x. Bun as the package manager. SDK 54 is what the App Store / Play Store Expo Go currently supports; the kit re-pins to the next SDK only after store Expo Go catches up.
