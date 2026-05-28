/**
 * Client-side action gate. Apple's tool-calling pre-validation pattern
 * adapted to a deterministic check that runs BEFORE any HMAC signing or
 * Worker round-trip. Catches three failure modes the user actually hits:
 *
 *   1. Malformed slug (someone hand-edits SecureStore, or a paste-URI flow
 *      drops a bad slug shape). Server returns 401 "slug mismatch", but the
 *      client burns a Worker request + a Xero call for nothing.
 *   2. UI double-fire (pull-to-refresh + tab switch race). Without an
 *      in-flight guard, two identical signed requests race; the second eats
 *      a Worker quota slot AND fails with "replay" 401 on the server.
 *   3. Tap spam (user mashes refresh). Server's 60/min per-slug rate limit
 *      will hold, but every fired request still costs Worker CPU-ms. A
 *      client-side 3-second floor stops spam at the source.
 *
 * Gate is per-process; no persistence. If the app force-quits and reopens,
 * the state resets; that is intentional, the server-side gate is the
 * load-bearing check.
 *
 * Reference: The AI Automators, "Apple Just Showed Every AI Builder How
 * To Stop Tool-Calling Errors Before They Execute" (2026-05-18). The Apple
 * pattern uses a reviewer model; we use deterministic schema + rate logic
 * because the action surface is small and well-typed. Same outcome, zero
 * inference cost.
 */

import { ACTION_REGISTRY, type ActionName } from "./actions";

const SLUG_RE = /^[0-9a-f]{12}$/;

const inFlight = new Set<string>();
const lastFireAt = new Map<string, number>();

export type ValidationResult =
  | { ok: true }
  | { ok: false; reason: string; retryAfterSeconds?: number };

export function validateBeforeFire(
  action: ActionName,
  args: { slug: string },
): ValidationResult {
  const def = ACTION_REGISTRY[action];
  if (!def) {
    return { ok: false, reason: `unknown action: ${action}` };
  }
  if (!SLUG_RE.test(args.slug)) {
    return { ok: false, reason: "slug shape invalid (expected 12 lowercase hex chars)" };
  }
  const key = `${action}:${args.slug}`;
  if (inFlight.has(key)) {
    return { ok: false, reason: "duplicate request already in flight" };
  }
  const now = Date.now();
  const last = lastFireAt.get(key) ?? 0;
  const elapsed = now - last;
  if (elapsed < def.minIntervalMs) {
    const retryAfterSeconds = Math.ceil((def.minIntervalMs - elapsed) / 1000);
    return {
      ok: false,
      reason: `rate limited; retry in ${retryAfterSeconds}s`,
      retryAfterSeconds,
    };
  }
  return { ok: true };
}

/** Marks an action+slug as in flight. Returns a release function the caller
 * MUST invoke in a finally block to clear the in-flight slot and stamp the
 * last-fire timestamp for the rate gate.
 */
export function markInFlight(action: ActionName, slug: string): () => void {
  const key = `${action}:${slug}`;
  inFlight.add(key);
  lastFireAt.set(key, Date.now());
  return () => {
    inFlight.delete(key);
  };
}

/** Test-only: reset all gate state. Not exported from index; the UI code
 * never needs it. */
export function _resetGateForTests(): void {
  inFlight.clear();
  lastFireAt.clear();
}
