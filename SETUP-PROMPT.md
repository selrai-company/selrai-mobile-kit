# Setup prompt

Paste the prompt below into Claude Code after running `install.sh` or `install.ps1`. It boots the kit and asks you the 3 questions it needs to scaffold your first app.

This prompt is the **non-technical entry point**. You do not need to know what Expo, React Native, or QR pairing mean. The kit handles the rest.

---

## The prompt

```
I just installed selrai-mobile-kit. Boot it.

Run /mobile-readiness-check first.

If readiness passes, ask me these three questions one at a time:

1. What does your business do, in one sentence?
2. Do you want a customer-facing app (clients use it) or a back-of-house app (only you and your team use it)?
3. Do you want to test on your own phone today, or do you only want to design the screens for now?

Use my answers to pick one of the 3 templates (pt-companion, service-quote, creator-companion) via /mobile-template-pick.

Once a template is picked, run /mobile-app-bootstrap to scaffold it, then /mobile-phone-preview to walk me through Expo Go + QR pairing if I said yes to question 3.

Do not show me raw error logs. If anything fails, give me a single-sentence next step.

Do not write any code outside the scaffolded project directory unless I explicitly ask.
```

---

## What happens next

After you paste the prompt:

1. **Readiness check** (under 30 seconds). The kit verifies Node + Bun + free disk + LAN.
2. **3 questions.** Plain English. No technical jargon.
3. **Template scaffolded** to a new directory in your current working folder.
4. **Phone preview** (if you said yes to question 3). The kit prints a QR code. Open Expo Go on your phone, scan, the app runs.

End-to-end target: under 20 minutes from `install.sh` to "app running on your own phone."

---

## If you get stuck

- The kit will not show you raw error messages. If it does, that is a Phase 0.1 stub gap. File an issue at https://github.com/selrai-company/selrai-mobile-kit/issues with the exact stub name shown.
- Workshop attendees: ping in the Workshop R&D space, the team responds same-day.
- Skool Premium members: post in the kit thread on Skool.
