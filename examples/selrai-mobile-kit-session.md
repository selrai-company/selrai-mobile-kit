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

## First-use

**You:** [a representative first task the kit supports]

> [Tool] Runs the kit's first-use entry point. Returns the expected artifact.

**Claude:** [Real output showing the kit's value.]

---

## Branches handled

- **Pre-existing install:** Phase 0 detects and runs verification only.
- **Partial install:** picks up where the previous run stopped.
- **Missing prereq:** walks the user through filling it, then continues.

---

## What this transcript proves

- Install is autonomous (Claude drives, user only does OAuth/hardware).
- Verification is real, not aspirational.
- Resume + partial + missing-prereq branches handled.
- An outsider can replicate the install end-to-end.

Captured against a real selrai-mobile-kit install in May 2026.
