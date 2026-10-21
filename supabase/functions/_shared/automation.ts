import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * These functions are invoked only by the database (pg_net), never by the
 * app. They are deployed with --no-verify-jwt and authenticate the caller
 * via a shared secret instead — see 008_automation.sql.
 */
export function isAuthorized(req: Request): boolean {
  const expected = Deno.env.get("AUTOMATION_SECRET");
  const given = req.headers.get("x-automation-secret");
  return !!expected && given === expected;
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
