---
name: mobile-readiness-check
description: "Pre-flight check before scaffolding a mobile app. Verifies Node 20+, Bun, free disk, LAN connectivity, and phone-pair compatibility. Returns one sentence on pass. Returns one fix step on fail. No raw error logs shown."
---

You are running a pre-flight readiness check for selrai-mobile-kit. Your job is to verify the user's machine can run an Expo app and pair it with a phone. You must never show raw error output. Every failure surfaces as a single-sentence next step.

## What to check (run in this order)

Run the following checks using bash tool calls. Collect results silently. Summarise only after all checks complete.

### 1. Node version

```bash
node -v
```

Pass condition: major version >= 20. Extract the integer with `node -v | sed -E 's/^v([0-9]+).*/\1/'` and compare.

Fail message: "Install Node 20+ from https://nodejs.org, then run /mobile-readiness-check again."

### 2. Bun presence

```bash
bun -v
```

Pass condition: any version output. Fail message: "Install Bun from https://bun.sh, then run /mobile-readiness-check again."

### 3. Free disk space

**macOS / Linux:**
```bash
df -BG . | awk 'NR==2{print $4}' | tr -d 'G'
```

**Windows:**
```powershell
[math]::Round((Get-PSDrive (Get-Location).Drive.Name).Free / 1GB, 1)
```

Pass condition: >= 2 GB free. Fail message: "Free at least 2 GB of disk space, then run /mobile-readiness-check again."

### 4. Network reachability (LAN check)

```bash
curl -s --max-time 5 --head https://registry.npmjs.org | head -1
```

Pass condition: HTTP 200 or 301 response. Fail message: "Check your internet connection, then run /mobile-readiness-check again."

### 5. Hotspot fallback path (phone-pair compatibility)

This check does not block readiness. It detects whether the user is on a corporate or restricted network that blocks Expo Go's LAN pairing port (19000).

```bash
curl -s --max-time 5 --head https://exp.host | head -1
```

If this fails but check 4 passed, set `hotspot_warning=true`. The Expo tunnel mode (via `--tunnel` flag) is the fallback. Do not fail readiness for this.

If `hotspot_warning=true`, add this note to the pass message: "Your network may block phone pairing over LAN. When prompted in /mobile-phone-preview, choose the tunnel option instead of LAN."

## How to respond

### All checks pass (no hotspot warning)

Respond with exactly this single sentence:

"Your machine is ready. Run /mobile-template-pick to choose a template for your app."

### All checks pass (hotspot warning present)

Respond with exactly two sentences:

"Your machine is ready. Your network may block phone pairing over LAN, so when /mobile-phone-preview runs, choose the tunnel option instead of LAN."

### Any check fails

Respond with the single-sentence fix from the first failing check only. Do not list multiple failures. Do not show command output. Do not show error traces.

Example (Node version fail): "Install Node 20+ from https://nodejs.org, then run /mobile-readiness-check again."

## Rules

- Never paste raw terminal output into the response.
- Never mention check numbers or check names in the user-facing response.
- Never show stack traces.
- If bash commands themselves error (e.g., command not found), treat that as a fail for that check and use the check's fail message.
- On Windows, substitute PowerShell equivalents for bash commands where noted.
