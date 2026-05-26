# xero-companion

**What it is:** A mobile home screen for owners on Xero. Two live cards: today's cash + who owes you. Backed by the `selrai-company/xero-proxy` Cloudflare Worker (HMAC-signed reads, no Xero credentials ever on the phone).

**Who it is for:** Small business owners, tradies, and AU bookkeepers who run weekly cash-flow numbers in their head and want a phone-shaped view of their Xero org.

**Current state:** v0.1.5 live. First-launch shows a pair screen (QR scan or paste URI). After pairing, home shows real cash-flow + AR ageing from the operator's Xero Custom Connection, fetched through xero-proxy.

## Pair this app

The operator runs `cloud/register.sh` on their desktop (in the xero-proxy repo) and prints a QR. Open Expo Go on your phone, scan the QR, the app pairs and remembers it.

## Run it

```bash
cd xero-companion && bun install && bun run start
```

Then scan the QR code with Expo Go on your phone. See `/mobile-phone-preview` if you need a step-by-step walk-through.

## Stack

Expo SDK 54 (pinned to 54.0.34) + React Native 0.81.5 + React 19.1 + Expo Router 6.0.x + NativeWind 4.2.x + expo-camera (QR) + expo-secure-store (creds) + expo-haptics + @noble/hashes (HMAC client). Bun as the package manager. SDK 54 is what the App Store / Play Store Expo Go currently supports; the kit re-pins to the next SDK only after store Expo Go catches up.
