# 26 UI Component Library

## Purpose
Documents the reusable, shared Flutter widgets located in `lib/shared/widgets/`.

## Existing Components

### 1. `AppLogoHeader`
- **Path:** `lib/shared/widgets/app_logo_header.dart`
- **Purpose:** Standardized header showing the institute logo and tagline. Used on all auth and static screens.
- **Props:** None. Sizing is internal and responsive.

### 2. `PrimaryButton`
- **Path:** `lib/shared/widgets/primary_button.dart`
- **Purpose:** The main call-to-action button (Gold background, Brown text).
- **Props:**
  - `label` (String): Button text.
  - `onPressed` (VoidCallback): Action on tap.
  - `isLoading` (bool): If true, replaces text with a `CircularProgressIndicator`.

## Planned Components (To Be Built)

### 3. `StatusBadge`
- **Purpose:** A small, pill-shaped container to show statuses (e.g., 'Pending', 'Paid', 'Present', 'Absent').
- **Design:** Background color at 15% opacity, text at 100% opacity based on semantic colors in `AppColors`.

### 4. `EmptyStateIllustration`
- **Purpose:** Shown when lists (homework, announcements, chat) are empty.
- **Design:** SVG illustration (e.g., open book, empty box) centered with a grey text description.

### 5. `AttachmentTile`
- **Purpose:** Displays an uploaded file (PDF or Image) inside Homework or Chat screens.
- **Design:** Icon indicating file type, filename, file size, and an action icon (download/view).

### 6. `UserAvatar`
- **Purpose:** Displays the profile photo of a student or teacher. Includes a fallback mechanism showing initials if the photo URL is null.
- **Props:** `url` (String?), `name` (String), `radius` (double). Uses `cached_network_image`.

## Cross-References
- [09_THEME.md](09_THEME.md)
- [07_UI_ANALYSIS.md](07_UI_ANALYSIS.md)
