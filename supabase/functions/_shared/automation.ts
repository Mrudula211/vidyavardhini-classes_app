import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * These functions are invoked only by the database (pg_net), never by the
 * app. They are deployed with --no-verify-jwt and authenticate the caller
 * via a shared secret instead — see 008_automation.sql.
 */
export function isAuthorized(req: Request): boolean {
  const expected = Deno.env.get("AUTOMATION_SECRET");
  const given = req.headers.get("x-automation-secret");
  if (!expected || !given) return false;
  return timingSafeEqual(given, expected);
}

/** Compares without leaking, through timing, how many leading characters match. */
function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  const n = Math.max(x.length, y.length);
  for (let i = 0; i < n; i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

export function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
