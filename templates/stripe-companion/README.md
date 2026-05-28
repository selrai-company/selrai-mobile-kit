# stripe-companion

**What it is:** A mobile home screen for Stripe operators. Two live cards: monthly recurring revenue (with MoM delta) and failed payments needing retry.

**Who it is for:** SaaS founders, subscription-box owners, and small teams who want their MRR + failed-payment triage on their phone without opening the Stripe dashboard.

**Current state:** Live data via the `selrai-company/stripe-proxy` Cloudflare Worker over the SelrAI-HMAC v1 scheme. Pair once by scanning a QR from `stripe-proxy`'s `cloud/register.sh`. stripe-proxy v0.0.1 returns deterministic stub data; v0.0.2 swaps for real Stripe API reads with no mobile-side change.

## Run it

```bash
cd stripe-companion && bun install && bun run start
```

Then scan the QR code with Expo Go on your phone. See `/mobile-phone-preview` for a step-by-step walk-through. On first launch the app shows the pair screen; scan the `stripeproxy://pair` QR your operator generated.

## Stack

Expo SDK 54 (pinned to 54.0.34) + React Native 0.81.5 + React 19.1 + Expo Router 6.0.x + NativeWind 4.2.x. `@noble/hashes` for HMAC signing, `expo-secure-store` for the pairing secret, `expo-camera` for the QR scan. Bun as the package manager.
