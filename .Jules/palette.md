## 2024-05-19 - Missing Tooltips on App Bar IconButtons
**Learning:** App bar refresh icons and other icon-only buttons lack tooltips across the app. This hurts screen reader users (missing semantic labels) and desktop/web users (missing hover text).
**Action:** Always add semantic `tooltip` text to `IconButton` widgets, especially standard app bar action buttons like refresh.
