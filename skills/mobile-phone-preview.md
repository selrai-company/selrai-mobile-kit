# /mobile-phone-preview

**Role:** Walk a non-technical user from a scaffolded Expo project to a live app running on their own phone. No Xcode. No Android Studio. No raw error logs.

---

## When this skill runs

`/mobile-app-bootstrap` calls this skill after the project directory is created and dependencies are installed. It also runs if the user explicitly says "show me how to see the app on my phone."

---

## Pre-conditions (verify silently before each step)

- The scaffolded project directory exists in the current working folder.
- `bun` is available (confirmed by `/mobile-readiness-check`).
- The user's phone and laptop are on the same wifi network, OR the user has acknowledged the hotspot fallback path (see Step 4 below).

If any pre-condition is missing, give one sentence: what is missing and what to do. No raw error output.

---

## Step 1: Install Expo Go

Tell the user:

> Open the App Store (iPhone) or Play Store (Android) on your phone. Search for **Expo Go**. Install the free app by Expo.

Wait for the user to confirm Expo Go is installed before continuing.

Phrase to watch for: "done", "installed", "got it", "yes", any affirmative.

---

## Step 2: Start the dev server

Run in the scaffolded project directory:

```
bun run start
```

This starts the Expo Metro bundler. A QR code will appear in the terminal.

Tell the user:

> I am starting the app server now. A black-and-white QR code will appear in this window in about 10 seconds. Do not close this window.

Do not surface the raw Metro output. If the server starts successfully, say:

> The server is running. The QR code is in the terminal.

If `bun run start` fails, give a single-sentence next step. See the error-handling section below.

---

## Step 3: Scan the QR code

Tell the user:

**iPhone:** Open the default Camera app. Point it at the QR code. Tap the Expo Go banner that appears at the top of the screen.

**Android:** Open Expo Go. Tap "Scan QR code" at the bottom of the screen. Point at the QR code.

The app will build and load on the phone. This takes 20 to 40 seconds on first load.

Tell the user:

> The first load takes about 30 seconds while the app compiles. After that, changes you make will reload in under 2 seconds.

---

## Step 4: Hotspot fallback (different wifi or corporate network)

Use this path when:
- The laptop is on one network (e.g., office wifi) and the phone is on another (e.g., mobile data).
- A corporate firewall blocks LAN device discovery.
- `/mobile-readiness-check` flagged a LAN pairing issue.

Tell the user:

> Your phone and laptop need to be on the same network for QR pairing to work. The fastest fix: turn on a personal hotspot on your phone, then connect your laptop's wifi to that hotspot. Both devices will then be on the same network.

Steps:
1. On iPhone: Settings > Personal Hotspot > Allow Others to Join (toggle on).
   On Android: Settings > Network > Hotspot > turn on.
2. On the laptop: connect wifi to the hotspot network (name matches the phone name by default).
3. Re-run `bun run start` in the project directory.
4. Scan the new QR code.

If hotspot is not an option (e.g., managed device), tell the user:

> We can switch to tunnel mode, which routes through Expo's servers instead of your local network. Type `s` in the terminal running the server, then press `t` to switch to tunnel mode. A new QR code will appear. Scan it.

Do not describe tunnel mode in detail. One sentence is enough.

---

## Error handling (what to say, not raw logs)

| What happened | What to say |
|---|---|
| `bun run start` fails with a dependency error | "One package did not install correctly. Run `bun install` in the project folder and then try `bun run start` again." |
| Metro bundler starts but QR code does not appear | "The server started but the QR code did not display. Press `q` in the terminal to quit, then run `bun run start` again." |
| Phone scans QR but app shows a red error screen | "The app loaded but hit an error on startup. This is usually a missing config. Type `/mobile-readiness-check` to re-run the checks, then try again." |
| Phone shows 'Could not connect to development server' | "Your phone could not reach your laptop. Try the hotspot fallback in Step 4 above." |
| Any other error | "Something unexpected happened. Copy the last line of the terminal output and paste it here. I will give you a single next step." |

Never paste a raw stack trace at the user. If the user pastes one, extract the one actionable line and respond to that only.

---

## Success state

The user sees the app's home screen on their phone. Confirm with:

> Your app is live on your phone. Any change you make in the project files reloads on the phone in under 2 seconds. You do not need to re-scan the QR code unless you restart the server.

Hand off to the user. No further steps required from this skill.

---

## References

- `skills/mobile-readiness-check.md` for the LAN / hotspot pre-check.
- `templates/README.md` for the project directory shape this skill expects.
- `SETUP-PROMPT.md` for how this skill fits into the full onboarding sequence.
