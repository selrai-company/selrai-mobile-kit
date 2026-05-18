# creator-companion

**What it is:** A mobile home screen for content creators. Entry points for today's content prompt and sending to GoHighLevel.

**Who it is for:** Solopreneur creators, coaches, and small media teams who want to manage their content pipeline and GHL social queue from their phone.

**Current state:** Phase 0.2 scaffold. 1 working home screen. Both buttons show a placeholder alert. Phase 0.3 wires them to your content calendar and GHL account.

## Run it

```bash
cd creator-companion && bun install && bun run start
```

Then scan the QR code with Expo Go on your phone. See `/mobile-phone-preview` if you need a step-by-step walk-through.

## Stack

Expo SDK 55 (pinned to 55.0.24) + React Native 0.83.6 + React 19.2 + Expo Router 55.0.x + NativeWind 4.2.x. Bun as the package manager.
