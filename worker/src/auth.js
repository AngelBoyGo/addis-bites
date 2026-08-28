/**
 * Addis Bites — minimal stateless JWT (HS256) issuance & verification.
 *
 * Uses the Web Crypto API (crypto.subtle) available in Workers and Node 24.
 * The signing secret comes from env.AUTH_SECRET; when it is absent the worker
 * falls back to the legacy `demo-<phone>` tokens so the offline harness and a
 * non-configured dev environment keep working. All money/trust decisions still
 * require a verified JWT in production.
 */

const enc = new TextEncoder();

function b64url(buf) {
  // Accept Buffer (Node), ArrayBuffer (Node subtle.sign), or Uint8Array.
  const bytesU8 = buf instanceof Uint8Array
    ? buf
    : new Uint8Array(buf instanceof ArrayBuffer ? buf : buf.buffer, buf.byteOffset, buf.byteLength);
  let binary = '';
  for (const b of bytesU8) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function b64urlDecode(str) {
  const b64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const pad = '='.repeat((4 - (b64.length % 4)) % 4);
  const binary = atob(b64 + pad);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function hmacKey(secret) {
  return crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

/** Signs a token payload {phone, role} with a short TTL. */
export async function signToken({ phone, role }, secret, ttlSeconds = 7 * 24 * 3600) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = { sub: phone, role, iat: now, exp: now + ttlSeconds };
  const signingInput = `${b64url(enc.encode(JSON.stringify(header)))}.${b64url(enc.encode(JSON.stringify(payload)))}`;
  const sig = await crypto.subtle.sign('HMAC', await hmacKey(secret), enc.encode(signingInput));
  return `${signingInput}.${b64url(sig)}`;
}

/**
 * Verifies and decodes a JWT. Returns {phone, role} or null on any failure
 * (bad structure, bad signature, expired).
 */
export async function verifyToken(token, secret) {
  try {
    const parts = String(token).split('.');
    if (parts.length !== 3) return null;
    const [h, p, s] = parts;
    const signingInput = `${h}.${p}`;
    const sig = b64urlDecode(s);
    const expected = await crypto.subtle.sign('HMAC', await hmacKey(secret), enc.encode(signingInput));
    if (!constantEquals(sig, expected)) return null;

    const payload = JSON.parse(new TextDecoder().decode(b64urlDecode(p)));
    if (typeof payload.exp !== 'number') return null;
    if (Math.floor(Date.now() / 1000) >= payload.exp) return null;
    return { phone: payload.sub, role: payload.role };
  } catch (_) {
    return null;
  }
}

function constantEquals(a, b) {
  const A = new Uint8Array(a);
  const B = new Uint8Array(b);
  if (A.length !== B.length) return false;
  let diff = 0;
  for (let i = 0; i < A.length; i++) diff |= A[i] ^ B[i];
  return diff === 0;
}