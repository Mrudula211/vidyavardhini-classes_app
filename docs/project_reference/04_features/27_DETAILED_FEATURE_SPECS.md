# 27 Detailed Feature Specifications

## Purpose
Expands on the PRD, providing granular technical specifications for complex features.

## 1. Teacher Geofence Attendance
**Goal:** Ensure teachers are physically present at the institute when marking their attendance.
**Logic:**
1. Admin sets `latitude`, `longitude`, and `radius_meters` in `geofence_settings`.
2. When the Teacher opens the app, `Geolocator` fetches current device coordinates.
3. Calculate distance using `Geolocator.distanceBetween()`.
4. If distance <= `radius_meters`, enable the "Mark Present" button.
5. Else, show warning: "You are outside the institute premises."
6. **Fallback:** Admin can manually correct/override teacher attendance via the Admin Dashboard.

## 2. Dynamic Fee Calculation
**Goal:** Calculate what a student owes for a given month.
**Logic:**
1. A student is assigned a `board` and `standard`.
2. `fee_structure` dictates the base monthly fee (e.g., CBSE 10th = ₹2000).
3. The Edge Function `monthly-fee-generate` runs on the 1st of the month, creating a row in `monthly_fees` with `expected_amount = 2000` and `status = pending`.
4. When a payment is recorded in `fee_payments` (e.g., ₹1000 paid), a PostgreSQL trigger fires.
5. Trigger calculates `SUM(amount)` from `fee_payments` for that `monthly_fee_id` and updates `monthly_fees.paid_amount`.
6. Trigger logic: If `paid_amount >= expected_amount`, set status to `paid`. If `paid_amount > 0`, set to `partially_paid`.

## 3. Real-time Doubt Chat
**Goal:** Allow students and teachers to communicate via text and images.
**Logic:**
1. Chat is partitioned by `room_id` (a composite or unique UUID linking Student A to Teacher B).
2. Flutter uses `Supabase.instance.client.from('messages').stream(primaryKey: ['id']).eq('room_id', currentRoomId)`.
3. This creates a WebSocket connection. Any insert/update to the `messages` table for that room pushes instantly to the client UI.
4. Images are uploaded to `chat-files` Storage bucket. The returned public URL is stored in `messages.content`.

## Cross-References
- [13_MODULES.md](13_MODULES.md)
- [28_BUSINESS_RULES.md](28_BUSINESS_RULES.md)
