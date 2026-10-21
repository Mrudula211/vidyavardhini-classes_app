// Exports every application table to a JSON file in the private `backups`
// Storage bucket and records the outcome on the backup_logs row.
// Invoked by the backup_logs_dispatch trigger (008_automation.sql) with
// { backup_id: string } — for both the daily cron and manual admin requests.

import { isAuthorized, json, serviceClient } from "../_shared/automation.ts";

// Keep in sync with supabase/migrations/001_initial_schema.sql.
const TABLES = [
  "users",
  "admin_profiles",
  "teacher_profiles",
  "student_profiles",
  "academic_years",
  "student_enrollments",
  "teacher_assignments",
  "student_attendance",
  "absence_reasons",
  "teacher_attendance",
  "homework",
  "homework_attachments",
  "classwork",
  "classwork_attachments",
  "chat_rooms",
  "messages",
  "announcements",
  "announcement_seen",
  "fee_structure",
  "monthly_fees",
  "fee_payments",
  "teacher_salary",
  "notifications",
  "geofence_settings",
  "teacher_timetable",
  "audit_logs",
  "promotion_history",
  "backup_logs",
];

const PAGE = 1000;
const RETENTION_DAYS = 30;

Deno.serve(async (req) => {
  if (!isAuthorized(req)) return json({ error: "unauthorized" }, 401);

  const { backup_id: backupId } = await req.json().catch(() => ({}));
  if (typeof backupId !== "string") return json({ error: "backup_id required" }, 400);

  const db = serviceClient();

  const fail = async (message: string) => {
    await db.from("backup_logs").update({
      status: "failed",
      error_msg: message.slice(0, 1000),
      completed_at: new Date().toISOString(),
    }).eq("id", backupId);
    return json({ error: message }, 500);
  };

  try {
    const dump: Record<string, unknown[]> = {};
    for (const table of TABLES) {
      const rows: unknown[] = [];
      for (let from = 0;; from += PAGE) {
        const { data, error } = await db.from(table).select("*").range(from, from + PAGE - 1);
        if (error) throw new Error(`${table}: ${error.message}`);
        rows.push(...data);
        if (data.length < PAGE) break;
      }
      dump[table] = rows;
    }

    const now = new Date();
    const payload = new TextEncoder().encode(JSON.stringify({
      format: "vidyavardhini-backup/v1",
      created_at: now.toISOString(),
      backup_id: backupId,
      tables: dump,
    }));
    const path = `${now.toISOString().slice(0, 10).replaceAll("-", "/")}/${backupId}.json`;

    const { error: uploadError } = await db.storage
      .from("backups")
      .upload(path, payload, { contentType: "application/json", upsert: true });
    if (uploadError) throw new Error(`upload: ${uploadError.message}`);

    await db.from("backup_logs").update({
      status: "success",
      storage_path: path,
      size_bytes: payload.byteLength,
      error_msg: null,
      completed_at: now.toISOString(),
    }).eq("id", backupId);

    await pruneOldBackups(db, now);

    return json({ backup_id: backupId, path, size_bytes: payload.byteLength });
  } catch (e) {
    console.error(e);
    return fail(e instanceof Error ? e.message : String(e));
  }
});

// Deletes backup files older than RETENTION_DAYS. backup_logs rows are kept
// as history; only the Storage objects are removed.
async function pruneOldBackups(db: ReturnType<typeof serviceClient>, now: Date) {
  const day = 86_400_000;
  const cutoff = new Date(now.getTime() - RETENTION_DAYS * day).toISOString();
  // Only look a week past the cutoff — older files were pruned on earlier runs.
  const floor = new Date(now.getTime() - (RETENTION_DAYS + 7) * day).toISOString();
  const { data: old } = await db
    .from("backup_logs")
    .select("storage_path")
    .eq("status", "success")
    .lt("created_at", cutoff)
    .gte("created_at", floor)
    .not("storage_path", "is", null);
  const paths = (old ?? []).map((r) => r.storage_path as string);
  if (paths.length > 0) await db.storage.from("backups").remove(paths);
}
