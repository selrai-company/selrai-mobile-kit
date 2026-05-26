/**
 * xero-proxy HTTP client with SelrAI-HMAC v1 signing.
 *
 * HMAC key derivation matches the Worker's actual computation
 * (`xero-proxy/src/durable-objects/tenant.ts computeHmac`):
 *
 *   1. Read hmacSecret (64 lowercase hex chars) from SecureStore.
 *   2. sha256Bytes = sha256(utf8(hmacSecret))           // 32 raw bytes
 *   3. sha256Hex   = bytesToHex(sha256Bytes)            // 64 char string
 *   4. key         = utf8(sha256Hex)                    // 64 UTF-8 bytes
 *   5. message     = `${ts}\n${nonce}\n${slug}\n${method}\n${path}`
 *   6. sig         = bytesToHex(hmacSha256(key, utf8(message)))
 *
 * The double conversion (bytes -> hex -> bytes) is intentional and matches the
 * Worker's stored shape. Do not skip the hex round-trip; the signatures will
 * mismatch.
 */

import { sha256 } from "@noble/hashes/sha256";
import { hmac } from "@noble/hashes/hmac";
import { bytesToHex } from "@noble/hashes/utils";
import * as Crypto from "expo-crypto";

import type { Credentials } from "./store";

export interface CashFlowResponse {
  slug: string;
  currency: string;
  balance_today: number;
  projected_90d: number;
  projected_low?: number;
  projected_high?: number;
  confidence?: number;
  ar_outstanding?: number;
  ap_outstanding?: number;
  as_of: string;
  stub?: boolean;
  stale?: boolean;
}

export interface ArAgeingBucket {
  days: string;
  total: number;
  contacts: Array<{ name: string; amount: number }>;
}

export interface ArAgeingResponse {
  slug: string;
  currency: string;
  total_overdue: number;
  buckets: ArAgeingBucket[];
  as_of: string;
  stub?: boolean;
  stale?: boolean;
}

function deriveKey(hmacSecretHex: string): Uint8Array {
  const enc = new TextEncoder();
  const secretBytes = enc.encode(hmacSecretHex);
  const digestBytes = sha256(secretBytes);
  const digestHex = bytesToHex(digestBytes);
  return enc.encode(digestHex);
}

async function randomNonceHex(): Promise<string> {
  const bytes = await Crypto.getRandomBytesAsync(16);
  return bytesToHex(bytes);
}

function buildAuthHeader(
  creds: Credentials,
  method: string,
  path: string,
  ts: number,
  nonce: string
): string {
  const key = deriveKey(creds.hmacSecret);
  const message = `${ts}\n${nonce}\n${creds.slug}\n${method}\n${path}`;
  const enc = new TextEncoder();
  const sigBytes = hmac(sha256, key, enc.encode(message));
  const sigHex = bytesToHex(sigBytes);
  return `SelrAI-HMAC v1 slug=${creds.slug};ts=${ts};nonce=${nonce};sig=${sigHex}`;
}

async function signedFetch(
  creds: Credentials,
  path: string
): Promise<Response> {
  const ts = Math.floor(Date.now() / 1000);
  const nonce = await randomNonceHex();
  const auth = buildAuthHeader(creds, "GET", path, ts, nonce);

  const url = `${creds.workerUrl}${path}`;
  return fetch(url, {
    method: "GET",
    headers: {
      Authorization: auth,
      Accept: "application/json",
    },
  });
}

export async function fetchCashFlow(creds: Credentials): Promise<CashFlowResponse> {
  const resp = await signedFetch(creds, `/${creds.slug}/cash-flow`);
  if (!resp.ok) {
    throw new Error(`cash-flow failed: ${resp.status}`);
  }
  return (await resp.json()) as CashFlowResponse;
}

export async function fetchArAgeing(creds: Credentials): Promise<ArAgeingResponse> {
  const resp = await signedFetch(creds, `/${creds.slug}/ar-ageing`);
  if (!resp.ok) {
    throw new Error(`ar-ageing failed: ${resp.status}`);
  }
  return (await resp.json()) as ArAgeingResponse;
}

/**
 * Validate a `xeroproxy://pair?url=...&slug=...&secret=...` URI and return the
 * parsed credentials. Returns null on any validation failure.
 */
export function parsePairUri(uri: string): Credentials | null {
  if (!uri.startsWith("xeroproxy://pair")) return null;
  let queryStart: number;
  try {
    queryStart = uri.indexOf("?");
    if (queryStart === -1) return null;
  } catch {
    return null;
  }
  const params = new URLSearchParams(uri.substring(queryStart + 1));
  const workerUrl = params.get("url");
  const slug = params.get("slug");
  const hmacSecret = params.get("secret");
  if (!workerUrl || !slug || !hmacSecret) return null;
  if (!workerUrl.startsWith("https://") && !workerUrl.startsWith("http://localhost")) {
    return null;
  }
  if (!/^[0-9a-f]{12}$/i.test(slug)) return null;
  if (!/^[0-9a-f]{64}$/i.test(hmacSecret)) return null;
  return { workerUrl, slug, hmacSecret };
}
