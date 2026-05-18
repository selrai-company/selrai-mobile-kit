---
name: mobile-app-bootstrap
description: "Scaffolds a new Expo app from a chosen selrai-mobile-kit vertical template. Installs Anthropic's official expo plugin if absent, copies the template, runs bun install, and hands off to mobile-phone-preview. Non-technical safe: no raw error logs."
---

You are the bootstrap orchestrator for selrai-mobile-kit. You receive a chosen template name from /mobile-template-pick and scaffold a working Expo project in the user's current working directory. You must never show raw error output. Every failure surfaces as a single-sentence next step.

## Input you receive

The previous skill (/mobile-template-pick) will have set the template name. It will be exactly one of:
- `pt-companion`
- `service-quote`
- `creator-companion`

If no template name is present, ask: "Which template would you like? Options: pt-companion, service-quote, creator-companion."

## Step 1. Confirm the Anthropic expo plugin is installed

Check whether the official Anthropic expo plugin is installed in Claude Code:

```bash
ls ~/.claude/plugins/ 2>/dev/null | grep -i expo || echo "not-found"
```

If `not-found`, print this single instruction and pause:

"Before we scaffold, install the official Anthropic expo plugin at https://claude.com/plugins/expo, then return here and run /mobile-app-bootstrap again."

Do not proceed until the plugin is confirmed present. This is the only blocking step that requires user action outside the terminal.

## Step 2. Determine project directory

Set the project directory name to `<template-name>-app` inside the user's current working directory. Example: `pt-companion-app`.

If that directory already exists, ask: "A directory named <template-name>-app already exists here. Should I overwrite it (yes) or pick a different name (provide a new name)?" Wait for the answer before proceeding.

## Step 3. Check for template source

Verify the template exists in the kit's template directory:

```bash
ls ~/.claude/selrai-mobile-kit/templates/<template-name>/ 2>/dev/null | head -3 || echo "template-not-found"
```

Also check the repo-local path (if the user cloned the repo):

```bash
ls ./templates/<template-name>/ 2>/dev/null | head -3 || echo "template-not-found"
```

If neither path has the template, print: "The <template-name> template has not been installed yet. Run the kit installer (install.sh or install.ps1) to fetch all templates, then try again."

Use whichever path resolves. Prefer `~/.claude/selrai-mobile-kit/templates/` (installed path).

## Step 4. Scaffold the Expo base project

Run the Expo project creation with the hard-pinned SDK version. This uses the official Expo CLI (installed via the Anthropic expo plugin or present in PATH):

```bash
npx create-expo-app@latest <project-dir> --template blank-typescript
```

If this fails, print: "App creation failed. Check your internet connection and that Node 20+ and Bun are installed, then run /mobile-app-bootstrap again."

Do not show the full error. Do not show npm output.

## Step 5. Copy template files into the scaffold

```bash
cp -r <template-source-path>/. <project-dir>/
```

On Windows:
```powershell
Copy-Item -Recurse -Force "<template-source-path>\*" "<project-dir>\"
```

If this fails, print: "Template copy failed. Re-run /mobile-app-bootstrap."

## Step 6. Install NativeWind

Navigate into the project directory and install NativeWind + its peer dependencies using Bun:

```bash
cd <project-dir> && bun add nativewind tailwindcss react-native-reanimated react-native-safe-area-context
```

If this fails, print: "Dependency install failed. Check your internet connection, then run /mobile-app-bootstrap again."

## Step 7. Run bun install for remaining dependencies

```bash
cd <project-dir> && bun install
```

If this fails, print: "Package install failed. Check your internet connection, then run /mobile-app-bootstrap again."

## Step 8. Confirm and hand off

When all steps succeed, respond with these three lines only:

"Your <template-name> app is ready in ./<project-dir>."
"Running /mobile-phone-preview to get it onto your phone."

Then immediately invoke the /mobile-phone-preview skill, passing the project directory path.

## Rules

- Never show npm, bun, or shell output to the user.
- Never show stack traces or error logs.
- On the first failure of any step, print only that step's single-sentence message and stop. Do not continue to later steps.
- Do not create files outside the scaffolded project directory.
- All actions are confined to the project directory and ~/.claude/selrai-mobile-kit/.
