## 2024-05-24 - Accessibility: Missing Tooltips on IconButtons
**Learning:** Found multiple instances where Flutter `IconButton` widgets with icon-only displays were missing `tooltip` properties across various feature modules (student, teacher, admin). This reduces accessibility for screen reader users and missing visual hover context.
**Action:** Always add `tooltip` string explaining the action when creating icon-only `IconButton` widgets in Flutter to ensure cross-platform accessibility.

## 2024-05-19 - Missing Tooltips on App Bar IconButtons
**Learning:** App bar refresh icons and other icon-only buttons lack tooltips across the app. This hurts screen reader users (missing semantic labels) and desktop/web users (missing hover text).
**Action:** Always add semantic `tooltip` text to `IconButton` widgets, especially standard app bar action buttons like refresh.
