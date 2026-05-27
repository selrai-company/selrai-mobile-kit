# selrai-mobile-kit templates

Three vertical scaffolds. Each is a self-contained Expo + React Native + Expo Router + NativeWind project.

## How mobile-app-bootstrap consumes these

`/mobile-app-bootstrap` picks one template (via `/mobile-template-pick`) and copies it into the user's working directory:

```bash
cp -r templates/<chosen>/ <user-cwd>/<app-name>/
cd <user-cwd>/<app-name>
bun install
bun run start
```

The template directory is the root of the new project. Nothing from the kit's outer directory is included.

## Directory shape (required, do not break)

Each template must contain:

```
<template-name>/
  package.json         (Expo SDK pin + scripts)
  app.json             (Expo config: name, slug, version 0.1.0)
  tsconfig.json        (extends expo/tsconfig.base, strict: true)
  global.css           (Tailwind base directives)
  tailwind.config.js   (NativeWind preset)
  metro.config.js      (NativeWind metro plugin)
  babel.config.js      (NativeWind babel preset)
  app/
    _layout.tsx        (Stack root, imports global.css)
    index.tsx          (home screen, 2 NativeWind buttons)
  assets/
    icon.png.placeholder
    splash.png.placeholder
  README.md            (15-line max, what + who + 1 run command)
```

Do not include `node_modules/`, `bun.lockb`, `ios/`, or `android/`. These are generated on the user's machine after `bun install`.

## Templates

| Name | Vertical | Header colour |
|---|---|---|
| `pt-companion` | Personal trainer: workout + client check-in | Blue (#1d4ed8) |
| `service-quote` | On-site service: new quote + today's jobs | Green (#15803d) |
| `creator-companion` | Content creator: daily prompt + GHL post | Purple (#7e22ce) |
| `stripe-companion` | Stripe operator: MRR snapshot + failed payments | Indigo (#635bff) |

`stripe-companion` is a live-data template: it pairs to the `selrai-company/stripe-proxy` Cloudflare Worker over SelrAI-HMAC v1, the same pattern `xero-companion` uses with `xero-proxy` and `creator-companion` uses with `ghl-proxy`.

## Adding another template

1. Copy an existing template directory: `cp -r templates/pt-companion templates/<new-name>`. For a live-data template, copy `stripe-companion` or `creator-companion` instead (they carry the `lib/` client + pair screen + action gate).
2. Update `package.json` name field, `app.json` name and slug, header colour in `app/_layout.tsx`.
3. Replace button labels (or card content + `lib/` route names for live templates) in `app/index.tsx`.
4. Update `assets/*.placeholder` notes if the vertical has a different icon shape.
5. Write a 15-line `README.md`.
6. Add a row to the table above.
7. Register the new template name in `skills/mobile-template-pick.md` (template-picker classifier).

All templates remain self-contained. No shared code. A future phase may extract a shared base; current templates ship duplicated by design. A live-data template additionally needs its backing Worker (a `*-proxy` repo) deployed and a pairing QR from that Worker's `cloud/register.sh`.
