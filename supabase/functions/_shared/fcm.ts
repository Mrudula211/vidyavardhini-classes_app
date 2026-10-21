/**
 * Minimal FCM HTTP v1 client. Authenticates with a Firebase service account
 * (JSON stored in the FIREBASE_SERVICE_ACCOUNT secret) using a self-signed
 * RS256 JWT exchanged for a Google OAuth access token.
 */

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface FcmMessage {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export type FcmResult = "sent" | "invalid_token" | "error";

let cached: { token: string; expiresAt: number } | null = null;

function serviceAccount(): ServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not set");
  return JSON.parse(raw);
}

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.expiresAt - 60 > now) return cached.token;

  const tokenUri = sa.token_uri ?? "https://oauth2.googleapis.com/token";
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  }));

  const pem = sa.private_key
    .replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );

  const res = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${base64url(signature)}`,
    }),
  });
  if (!res.ok) throw new Error(`OAuth token exchange failed: ${await res.text()}`);

  const body = await res.json();
  cached = { token: body.access_token, expiresAt: now + body.expires_in };
  return cached.token;
}

export async function sendFcm(messages: FcmMessage[]): Promise<FcmResult[]> {
  if (messages.length === 0) return [];
  const sa = serviceAccount();
  const token = await accessToken(sa);
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  const sendOne = async (m: FcmMessage): Promise<FcmResult> => {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: m.token,
          notification: { title: m.title, body: m.body },
          data: m.data ?? {},
          android: { priority: "HIGH" },
        },
      }),
    });
    if (res.ok) return "sent";
    const text = await res.text();
    // UNREGISTERED / INVALID_ARGUMENT on the token mean the device is gone.
    if (res.status === 404 || text.includes("UNREGISTERED")) return "invalid_token";
    if (res.status === 400 && text.includes("registration token")) return "invalid_token";
    console.error(`FCM send failed (${res.status}): ${text}`);
    return "error";
  };

  // Small batches keep us well under FCM's per-project rate limits.
  const results: FcmResult[] = [];
  for (let i = 0; i < messages.length; i += 50) {
    results.push(...await Promise.all(messages.slice(i, i + 50).map(sendOne)));
  }
  return results;
}
