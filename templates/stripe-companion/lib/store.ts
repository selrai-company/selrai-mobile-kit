/**
 * Credential storage for the stripe-companion pairing state.
 *
 * Three values persist in expo-secure-store after the operator pairs this app
 * to their stripe-proxy Worker:
 *   - workerUrl: HTTPS base URL (e.g. https://stripe-proxy.foo.workers.dev)
 *   - slug: 12 lowercase hex chars
 *   - hmacSecret: 64 lowercase hex chars (32 random bytes from the Worker's /register)
 *
 * SecureStore uses iOS Keychain + Android EncryptedSharedPreferences under the
 * hood, so values never sit in plaintext on the device.
 */

import * as SecureStore from "expo-secure-store";

const K_URL = "stripeproxy.url";
const K_SLUG = "stripeproxy.slug";
const K_SECRET = "stripeproxy.secret";

export interface Credentials {
  workerUrl: string;
  slug: string;
  hmacSecret: string;
}

export async function getCredentials(): Promise<Credentials | null> {
  const [workerUrl, slug, hmacSecret] = await Promise.all([
    SecureStore.getItemAsync(K_URL),
    SecureStore.getItemAsync(K_SLUG),
    SecureStore.getItemAsync(K_SECRET),
  ]);
  if (!workerUrl || !slug || !hmacSecret) return null;
  return { workerUrl, slug, hmacSecret };
}

export async function saveCredentials(creds: Credentials): Promise<void> {
  await Promise.all([
    SecureStore.setItemAsync(K_URL, creds.workerUrl),
    SecureStore.setItemAsync(K_SLUG, creds.slug),
    SecureStore.setItemAsync(K_SECRET, creds.hmacSecret),
  ]);
}

export async function clearCredentials(): Promise<void> {
  await Promise.all([
    SecureStore.deleteItemAsync(K_URL),
    SecureStore.deleteItemAsync(K_SLUG),
    SecureStore.deleteItemAsync(K_SECRET),
  ]);
}
