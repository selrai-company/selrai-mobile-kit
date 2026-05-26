# xero-companion

**What it is:** A mobile home screen for owners on Xero. Glance at today's cash and who owes you, from the same Xero org that runs your books.

**Who it is for:** Small business owners, tradies, and bookkeepers who run weekly cash-flow numbers in their head and want a phone-shaped view of their Xero org.

**Current state:** Phase 0.2 scaffold. 1 working home screen. Both buttons show a placeholder alert. Phase 0.3 wires them to live Xero data via the `xero-proxy` Cloudflare Worker (sibling repo, sits on top of `xero-skills` v0.2's Custom Connection auth + `@xeroapi/xero-mcp-server`).

## Run it

```bash
cd xero-companion && bun install && bun run start
```

Then scan the QR code with Expo Go on your phone. See `/mobile-phone-preview` if you need a step-by-step walk-through.

## Stack

Expo SDK 54 (pinned to 54.0.34) + React Native 0.81.5 + React 19.1 + Expo Router 6.0.x + NativeWind 4.2.x. Bun as the package manager. SDK 54 is what the App Store / Play Store Expo Go currently supports; the kit re-pins to the next SDK only after store Expo Go catches up.
