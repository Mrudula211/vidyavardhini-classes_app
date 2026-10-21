// Delivers FCM pushes for newly inserted `notifications` rows.
// Invoked by the notifications_push_dispatch trigger (008_automation.sql)
// with { notification_ids: string[] }.

import { isAuthorized, json, serviceClient } from "../_shared/automation.ts";
import { FcmMessage, sendFcm } from "../_shared/fcm.ts";

Deno.serve(async (req) => {
  if (!isAuthorized(req)) return json({ error: "unauthorized" }, 401);

  const { notification_ids: ids } = await req.json().catch(() => ({}));
  if (!Array.isArray(ids) || ids.length === 0) {
    return json({ error: "notification_ids required" }, 400);
  }

  const db = serviceClient();
  const { data: rows, error } = await db
    .from("notifications")
    .select("id, user_id, title, body, type, data, users!inner(fcm_token, is_active)")
    .in("id", ids);
  if (error) return json({ error: error.message }, 500);

  const targets = (rows ?? []).filter((r) => {
    const user = r.users as unknown as { fcm_token: string | null; is_active: boolean };
    return user.is_active && !!user.fcm_token;
  });

  const messages: FcmMessage[] = targets.map((r) => {
    const user = r.users as unknown as { fcm_token: string };
    const data: Record<string, string> = { notification_id: r.id, type: r.type };
    // FCM data values must be strings.
    for (const [k, v] of Object.entries((r.data ?? {}) as Record<string, unknown>)) {
      data[k] = typeof v === "string" ? v : JSON.stringify(v);
    }
    return { token: user.fcm_token, title: r.title, body: r.body, data };
  });

  let results;
  try {
    results = await sendFcm(messages);
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }

  const sentIds = targets.filter((_, i) => results[i] === "sent").map((r) => r.id);
  const staleUsers = targets.filter((_, i) => results[i] === "invalid_token").map((r) => r.user_id);

  if (sentIds.length > 0) {
    await db.from("notifications").update({ sent_at: new Date().toISOString() }).in("id", sentIds);
  }
  if (staleUsers.length > 0) {
    await db.from("users").update({ fcm_token: null }).in("id", staleUsers);
  }

  return json({
    requested: ids.length,
    sent: sentIds.length,
    no_token: (rows?.length ?? 0) - targets.length,
    invalid_tokens: staleUsers.length,
    errors: results.filter((r) => r === "error").length,
  });
});
