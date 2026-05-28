/**
 * Action registry.
 *
 * Every Worker call the mobile makes is named, typed, and registered here.
 * No free-form path strings sprinkled through the UI. This is the single
 * source of truth for which reads the stripe-companion is allowed to fire.
 *
 * Adding a new endpoint: add the name to ActionName, add the definition to
 * ACTION_REGISTRY, then call it via validateBeforeFire(name, args) +
 * markInFlight(name, slug) in lib/stripe-client.ts. The validate gate refuses
 * any call to an unknown action name.
 */

export type ActionName = "mrr-snapshot.read" | "failed-payments.read";

export interface ActionDef {
  method: "GET";
  /** Path template; `:slug` is the only substitution token. */
  pathTemplate: string;
  /** Minimum interval between two fires of the same action+slug, in ms.
   * Client-side soft rate limit, defense in depth alongside the Worker's
   * per-slug 60/min server-side gate. Stops double-tap on the UI from
   * burning two Worker requests + two Stripe API calls. */
  minIntervalMs: number;
}

export const ACTION_REGISTRY: Record<ActionName, ActionDef> = {
  "mrr-snapshot.read": {
    method: "GET",
    pathTemplate: "/:slug/mrr-snapshot",
    minIntervalMs: 3000,
  },
  "failed-payments.read": {
    method: "GET",
    pathTemplate: "/:slug/failed-payments",
    minIntervalMs: 3000,
  },
};

export function resolvePath(action: ActionName, slug: string): string {
  const def = ACTION_REGISTRY[action];
  if (!def) {
    // Unreachable: ActionName is a closed union and every member is registered.
    // The runtime check exists to satisfy noUncheckedIndexedAccess.
    throw new Error(`resolvePath: action '${action}' missing from ACTION_REGISTRY`);
  }
  return def.pathTemplate.replace(":slug", slug);
}
