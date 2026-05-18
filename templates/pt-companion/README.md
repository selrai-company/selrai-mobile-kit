# pt-companion

**What it is:** A mobile home screen for personal trainers. Shows today's workout and a client check-in entry point.

**Who it is for:** Solo PTs and small training businesses who want a branded app on their clients' phones without hiring a developer.

**Current state:** Phase 0.2 scaffold. 1 working home screen. Both buttons show a placeholder alert. Phase 0.3 wires them to your schedule and client data.

## Run it

```bash
cd pt-companion && bun install && bun run start
```

Then scan the QR code with Expo Go on your phone. See `/mobile-phone-preview` if you need a step-by-step walk-through.

## Stack

Expo SDK 55 (pinned to 55.0.24) + React Native 0.83.6 + React 19.2 + Expo Router 55.0.x + NativeWind 4.2.x. Bun as the package manager.
