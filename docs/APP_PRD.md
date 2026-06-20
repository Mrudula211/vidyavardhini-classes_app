# APP_PRD.md — Vidyavardhini Classes

**Version:** 1.0  
**Status:** Development Started  
**Client:** Mrs. Siddhi Gharat  
**Institution:** Vidyavardhini Classes  
**Date:** June 2026  

---

## 1. Executive Summary

Vidyavardhini Classes is a coaching institute running SSC and CBSE batches for standards 1st–10th. The current workflow relies on WhatsApp groups for homework, fee reminders, and announcements. This application replaces WhatsApp with a purpose-built ERP that centralises student management, attendance, fees, teacher management, and parent communication.

**Scale:** 1 Admin · 5 Teachers · 140+ Students  
**Boards:** SSC (1st–10th) · CBSE (1st–10th)  
**Platform:** Android (primary) · iOS (secondary)

---

## 2. Problem Statement

| Current Pain | Impact |
|---|---|
| WhatsApp groups for homework | No accountability, mixed messages |
| Manual fee register | Errors, no reminders, lost records |
| No attendance system | No tracking, disputes |
| No teacher salary automation | Manual calculation errors |
| No academic year archival | Old data lost |
| No audit trail | Cannot trace who changed what |

---

## 3. User Roles

### 3.1 Admin (1 account)

The owner of the coaching class. Complete control over the system.

**Login Flow:** Phone → OTP → Admin Access Code → Password → Dashboard

**Capabilities:**
- Approve / reject / ban students
- Assign Student IDs
- Manage teacher profiles and assignments
- Set and collect fees
- View revenue analytics
- Create all types of announcements
- Promote students to next academic year
- View audit logs
- Restore backups
- Configure geofence for teacher attendance
- Manually correct teacher attendance

### 3.2 Teacher (up to 10 accounts)

Instructors assigned to specific classes.

**Login Flow:** Phone → OTP → Teacher Access Code → Dashboard

**Capabilities:**
- Mark student attendance for assigned classes
- Upload homework (text / image / PDF)
- Upload classwork (notes / board photos / PDF)
- Reply to student doubt messages
- View own profile, timetable, salary
- View announcements

**Cannot:**
- Edit fees or revenue data
- Approve students
- Promote students
- Access admin settings or audit logs

### 3.3 Student (140+ accounts)

Enrolled learners.

**Registration Flow:** Phone → OTP → Registration Form → Pending Approval  
**Post-Approval Login:** Phone → OTP → Dashboard

**Capabilities:**
- View homework and classwork for their class
- View own attendance
- View own fee status
- Send doubt messages to teacher
- View announcements

**Cannot:**
- See other students' data
- Edit fees
- Access data from previous academic years

---

## 4. Authentication

### 4.1 OTP System
- Supabase Auth with phone/OTP (SMS via Twilio or MSG91)
- Session stored securely on device
- Token refresh handled by Supabase SDK

### 4.2 Access Codes
- **Admin Access Code:** 6-digit code set during first setup, stored hashed
- **Teacher Access Code:** Unique per teacher, assigned by admin, stored hashed
- Codes are required as a second factor after OTP

### 4.3 Student Password
- Set by student after admin approval (first login after approval)
- Bcrypt hashed, stored in Supabase

### 4.4 Session Security
- JWT from Supabase Auth
- Role claim (`admin` / `teacher` / `student`) embedded in JWT
- RLS policies enforce role-based access at database level

---

## 5. Student Management

### 5.1 Registration Fields

| Field | Type | Required |
|---|---|---|
| Full Name | Text | Yes |
| Gender | Enum (Male/Female/Other) | Yes |
| Date of Birth | Date | Yes |
| Parent Name | Text | Yes |
| Parent Mobile | Phone | Yes |
| WhatsApp Number | Phone | Yes |
| Email Address | Email | Yes |
| School Name | Text | Yes |
| Board | Enum (SSC/CBSE) | Yes |
| Standard | Enum (1st–10th) | Yes |
| Profile Photo | Image | Optional |

### 5.2 Student ID Format
- Format: `STU` + 4-digit zero-padded number
- Examples: STU0001, STU0142
- Auto-suggested by system (next available)
- Admin can edit before approval
- **Permanent. Never reused.**

### 5.3 Student Status Lifecycle

```
Registration → Pending
Pending → Active (admin approves)
Pending → Rejected (admin rejects)
Active → Inactive (admin deactivates)
Active → Banned (admin bans)
Inactive → Active (admin reactivates)
Active → Archived (academic year end)
```

### 5.4 Admin Approval Actions

| Action | Result |
|---|---|
| Approve | Student gets Active status, assigned ID, notified |
| Reject | Student notified with reason, data retained |
| Ban | Student blocked, cannot re-register |

---

## 6. Teacher Management

### 6.1 Teacher Profile Fields

| Field | Notes |
|---|---|
| Teacher ID | TCH0001 format, assigned by admin |
| Full Name | |
| Gender | |
| Date of Birth | |
| Mobile Number | |
| Email Address | |
| Joining Date | |
| Profile Photo | Optional |
| Monthly Salary | Set by admin, ₹ value |
| Assigned Classes | Board + Standard + Subject combinations |

### 6.2 Class Assignment

Admin assigns each teacher to one or more `Board + Standard + Subject` combinations.

Example:
```
Teacher A (Class Teacher):
  SSC 4th — All Subjects
  SSC 5th — All Subjects

Teacher B (Math Specialist):
  SSC 6th–10th — Mathematics
  CBSE 6th–10th — Mathematics
```

A teacher sees only their assigned classes in homework, classwork, and attendance.

### 6.3 Teacher Timetable

Admin sets per-teacher:
- Working days (Mon–Sat checkboxes)
- Per-day: start time, end time, class segments

Teachers can view timetable, cannot edit.

---

## 7. Attendance

### 7.1 Student Attendance

- Teachers mark attendance daily per class
- Per student: Present / Absent
- If Absent: reason required (Sick / Family Function / Travel / Personal / Other)
- Stored date-wise in DB
- Unique constraint: one record per student per date

**Student View:**
```
Present:  22 Days
Absent:    2 Days
Percentage: 91.67%
```

Per-date view shows: Date | Status | Reason

### 7.2 Teacher Attendance (Geofence)

Admin configures:
- Latitude / Longitude (coaching centre location)
- Allowed radius (default: 100m)

When a teacher's device enters the geofence:
- GPS coordinates logged
- Attendance auto-marked Present with check-in timestamp

**Manual Correction:**
- Admin can correct any teacher's attendance
- Reason required
- Every correction logged immutably in audit_logs

### 7.3 Attendance Heatmap (Admin View)

Calendar view with colour coding:
- Green: ≥85% attendance
- Yellow: 60–84% attendance
- Red: <60% attendance

---

## 8. Homework System

### 8.1 Teacher Upload

Fields:
- Subject
- Title
- Description (optional)
- Due Date
- Attachments: Text / Images / PDFs (multiple allowed)

Scoped to: Board + Standard + Academic Year

### 8.2 Student View

Students see homework for their Board + Standard only.  
Display: Subject · Teacher Name · Upload Date · Due Date · Attachments

Students cannot submit homework via app (view-only in v1).

---

## 9. Classwork System

Similar to homework but without due date.

Types: Notes · Board Photos · Lesson Summary · PDFs

Scoped to: Board + Standard + Academic Year  
Students: read-only

---

## 10. Private Doubt Chat

- One chat room per Student ↔ Teacher pair
- Students can message any teacher assigned to their class
- Realtime via Supabase Realtime
- Admin can read any conversation (monitoring)
- No student can see another student's messages (enforced by RLS)
- File sharing supported (images, PDFs)

---

## 11. Announcements

### 11.1 Types

| Type | Visible To | Priority |
|---|---|---|
| General | All (students + teachers + admin) | Normal |
| Staff | Teachers + Admin only | Normal |
| Emergency | All | Urgent — shown as popup + banner + push |

### 11.2 Targeting

General announcements can target:
- All boards and standards
- Specific board (SSC or CBSE)
- Specific standard (e.g., 8th only)

### 11.3 Read Tracking

Admin sees per announcement:
- Seen By: N students / teachers
- Not Seen By: list of names

---

## 12. Fee Management

### 12.1 Fee Setup

Admin sets monthly fee per student per academic year.  
Default: ₹0 (must be set before the month starts).

### 12.2 Auto-Generated Monthly Records

On the 1st of each month, the system auto-creates a `monthly_fees` record for every active student:
```
Expected: ₹1500 (from fee_structure)
Paid: ₹0
Remaining: ₹1500
Status: Pending
```

### 12.3 Payment Recording (Admin Only)

Admin records payment:
- Amount paid
- Payment method: Cash / UPI / Bank Transfer / Cheque
- Payment date
- Reference number (optional)
- Notes (optional)

System auto-calculates status:
- Paid = 0 → **Pending**
- 0 < Paid < Expected → **Partially Paid**
- Paid ≥ Expected → **Paid**

Partial payments are additive (multiple payments per month supported).

### 12.4 Student Fee View

Students see per-month:
```
July 2027
Expected: ₹1500
Paid: ₹1000
Remaining: ₹500
Status: Partially Paid
Method: Cash
Date: 10 July 2027
```

### 12.5 Fee Reminders

**Automatic:** 10th of every month — push notification to students with Pending or Partially Paid status.  
**Manual:** Admin can trigger reminder for any student at any time.

---

## 13. Teacher Salary

### 13.1 Calculation

```
Daily Salary = Monthly Salary ÷ Working Days in Month
Earned Salary = Daily Salary × Present Days
```

Example:
```
Monthly Salary: ₹7000
Working Days: 24
Daily Salary: ₹291.67
Present Days: 22
Earned Salary: ₹6416.67
```

### 13.2 Teacher Salary View

Teachers can see:
- Present Days / Absent Days
- Daily Salary
- Earned Salary
- Payment Status (Pending / Paid)
- Payment Date and Method

Cannot edit.

---

## 14. Revenue Dashboard (Admin Only)

### 14.1 Monthly View

```
Expected Revenue:  ₹2,10,000   (all students × monthly fee)
Collected:         ₹1,95,000
Pending:           ₹15,000
Collection Rate:   92.86%
```

### 14.2 Yearly View

- Bar chart: monthly collected vs expected
- Yearly total collected
- Yearly total pending

---

## 15. Academic Year Management

### 15.1 Year Format

`YYYY-YY` (e.g., 2026-27)

Each academic year is a separate entity. All records (attendance, fees, homework) are tagged with `academic_year_id`.

### 15.2 Student Promotion

**Path:** Admin Settings → Academic Year → Promote Students

**Confirmation Flow:**
1. Warning screen describing what will happen
2. Admin types `CONFIRM`
3. Admin enters password
4. OTP sent to admin phone
5. OTP verified
6. Promotion executes

**Promotion Logic:**
- SSC 1st → SSC 2nd, ..., SSC 9th → SSC 10th
- SSC 10th → Archived (graduated)
- CBSE same pattern
- Inactive students are not promoted (marked Archived)

### 15.3 Data Isolation

- Current academic year: All roles can access (subject to role permissions)
- Previous academic years: **Admin only**
- Students/Teachers cannot access any historical year data

---

## 16. Audit Logs

Logged events:
- Student approved / rejected / banned
- Fee payment added or edited
- Attendance corrected manually
- Salary payment recorded
- Student promoted
- Homework / classwork uploaded or deleted
- Teacher added or edited
- Admin settings changed

Log record: Timestamp · Performed By · Action · Entity Type · Entity ID · Old Value · New Value

**Immutable:** No UPDATE or DELETE operations on `audit_logs` table (enforced by RLS: insert-only).

---

## 17. Notifications

| Event | Recipients | Type |
|---|---|---|
| Homework uploaded | Students in class | Push + In-app |
| Classwork uploaded | Students in class | Push + In-app |
| Fee reminder (10th) | Students with pending fees | Push + In-app |
| New announcement | Targeted users | Push + In-app |
| Emergency announcement | All | Push + Popup |
| Student approved | Student | Push + In-app |
| Student rejected | Student | Push + In-app |
| Salary paid | Teacher | Push + In-app |
| New doubt message | Teacher | Push + In-app |
| Teacher reply | Student | Push + In-app |

---

## 18. Backup System

- **Automatic:** Daily cloud backup to Supabase Storage
- **Manual:** Admin can trigger backup at any time
- **Restore:** Admin can restore from a specific backup point
- Backup log records: date, size, status, initiated-by

---

## 19. Performance Requirements

| Metric | Target |
|---|---|
| App cold start | < 3 seconds |
| Screen load (list) | < 1 second |
| File upload (5MB) | < 10 seconds |
| Concurrent users | 150+ without degradation |
| Offline support | Read-only from Hive cache |
| Attendance marking | < 2 seconds round-trip |

---

## 20. Non-Functional Requirements

- **Security:** All data encrypted in transit (HTTPS/WSS). Supabase RLS on every table. No sensitive data in local cache unencrypted.
- **Reliability:** 99.5% uptime (Supabase SLA).
- **Scalability:** Schema supports multiple academic years and growing student count.
- **Accessibility:** Minimum touch target 48×48dp. System font scaling support.
- **Compliance:** No PII in logs. Profile photos stored in private buckets.

---

## 21. Out of Scope (v1)

- Student homework submission (view-only)
- Online fee payment gateway
- Video classes / live streaming
- Parent separate login (parents use student account)
- SMS notifications (push only)
- Web admin panel

---

## 22. Success Metrics

- Admin can approve a new student in < 2 minutes
- Fee collection rate visibility: real-time
- Attendance marking for a class of 30 students: < 5 minutes
- Zero WhatsApp usage for homework and fee reminders after 1 month
