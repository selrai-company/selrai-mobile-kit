/**
 * Unit coverage for the client-side action gate (lib/validate.ts).
 *
 * Run with `bun test` (Bun's built-in runner; no extra dependency). The gate
 * is the mobile-side security defense that runs BEFORE HMAC signing and any
 * Worker round-trip, so it earns deterministic coverage of every reject path
 * plus the happy path and the release lifecycle.
 *
 * This file is byte-for-byte portable across the live-data templates
 * (creator-companion, xero-companion, stripe-companion) except for the two
 * ActionName literals; the gate logic itself is identical by design.
 */

import { test, expect, beforeEach } from "bun:test";
import { validateBeforeFire, markInFlight, _resetGateForTests } from "./validate";

const SLUG = "0123456789ab"; // 12 lowercase hex chars
const BAD_SLUG = "NOPE";

beforeEach(() => {
  _resetGateForTests();
});

test("valid action + valid slug passes", () => {
  const r = validateBeforeFire("cash-flow.read", { slug: SLUG });
  expect(r.ok).toBe(true);
});

test("unknown action is rejected", () => {
  // Cast through never: the closed union would reject this at compile time,
  // but a malformed call site or a future un-registered action must still be
  // refused at runtime.
  const r = validateBeforeFire("does-not-exist.read" as never, { slug: SLUG });
  expect(r.ok).toBe(false);
  if (!r.ok) expect(r.reason).toContain("unknown action");
});

test("malformed slug is rejected before any network call", () => {
  const r = validateBeforeFire("cash-flow.read", { slug: BAD_SLUG });
  expect(r.ok).toBe(false);
  if (!r.ok) expect(r.reason).toContain("slug shape invalid");
});

test("duplicate in-flight request is rejected", () => {
  const release = markInFlight("cash-flow.read", SLUG);
  try {
    const r = validateBeforeFire("cash-flow.read", { slug: SLUG });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reason).toContain("in flight");
  } finally {
    release();
  }
});

test("releasing the in-flight slot clears the duplicate guard", () => {
  const release = markInFlight("cash-flow.read", SLUG);
  release();
  // The 3-second rate floor still applies because markInFlight stamped a
  // last-fire timestamp; so immediately after release we expect a rate-limit
  // reject, NOT an in-flight reject. This proves release cleared the in-flight
  // slot (otherwise the reason would mention "in flight").
  const r = validateBeforeFire("cash-flow.read", { slug: SLUG });
  expect(r.ok).toBe(false);
  if (!r.ok) expect(r.reason).toContain("rate limited");
});

test("rate floor rejects a same-action repeat with a retry hint", () => {
  const release = markInFlight("cash-flow.read", SLUG);
  release();
  const r = validateBeforeFire("cash-flow.read", { slug: SLUG });
  expect(r.ok).toBe(false);
  if (!r.ok) {
    expect(r.reason).toContain("rate limited");
    expect(typeof r.retryAfterSeconds).toBe("number");
    expect(r.retryAfterSeconds).toBeGreaterThan(0);
    expect(r.retryAfterSeconds).toBeLessThanOrEqual(3);
  }
});

test("a different action+slug is independent of another's in-flight slot", () => {
  const release = markInFlight("cash-flow.read", SLUG);
  try {
    // ar-ageing.read on the same slug has its own bucket; not blocked by the
    // cash-flow in-flight slot, and no prior fire so no rate floor.
    const r = validateBeforeFire("ar-ageing.read", { slug: SLUG });
    expect(r.ok).toBe(true);
  } finally {
    release();
  }
});

test("gate state resets between tests (isolation sanity)", () => {
  // beforeEach calls _resetGateForTests, so a fresh valid call must pass even
  // though prior tests stamped timestamps for this same action+slug.
  const r = validateBeforeFire("cash-flow.read", { slug: SLUG });
  expect(r.ok).toBe(true);
});
