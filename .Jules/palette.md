## 2024-07-24 - Missing Semantic Labels on Icon Buttons
**Learning:** This Flutter application frequently uses `IconButton` for navigation (Back) and password toggling (Show/Hide) without providing the `tooltip` property. This causes an accessibility issue as screen readers cannot announce the button's purpose, and desktop/web users don't get hover context.
**Action:** Always include a descriptive `tooltip` property on `IconButton` and other icon-only interactive widgets (e.g., `tooltip: 'Show password'`) to ensure full semantic labeling and hover support across all platforms.
## 2026-08-25 - Improve Contrast on Destructive Actions
**Learning:** Destructive actions with a `backgroundColor: Colors.red` on `ElevatedButton` might not have sufficient text contrast if the foregroundColor is not explicitly set, particularly depending on the app theme defaults.
**Action:** Always specify `foregroundColor: Colors.white` when using red backgrounds for warnings/destructive buttons to ensure accessibility and readability.
