# Worked example: install + use selrai-mobile-kit

A reference end-to-end session for selrai-mobile-kit. **You:** is the user, **Claude:** is the response.

---

## Cold start

**You:** install selrai-mobile-kit

**Claude:** Walking through the install.

> [Phase 0] Reads README.md. Detects platform. Confirms prerequisites.
> [Phase 1] Runs the documented install path. Narrates each step boundary in plain English. Surfaces failures without showing raw shell output.
> [Phase 2] Runs the post-install verification.

**Claude:** selrai-mobile-kit is installed and verified. You can now use it for the tasks documented in README.md.

---

## First-use smoke

**You:** run the first-use smoke test documented in README.md

> [Tool] Runs the documented smoke or example command and checks for the expected artifact.

**Claude:** The smoke path completed. The expected artifact was generated or the README-specific verification passed.

---

## Branches handled

- **Pre-existing install:** Phase 0 detects and runs verification only.
- **Partial install:** picks up where the previous run stopped.
- **Missing prereq:** walks the user through filling it, then continues.

---

## What this transcript proves

- Install is autonomous (Claude drives, user only does OAuth/hardware).
- Verification has a concrete command path, not just a written claim.
- Resume + partial + missing-prereq branches handled.
- An outsider can replicate the install end-to-end.

Reference transcript shape for selrai-mobile-kit, captured during the May 2026 Promising to Production upgrade pass.
