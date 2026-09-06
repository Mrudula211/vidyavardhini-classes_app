## 2024-07-24 - Missing Semantic Labels on Icon Buttons
**Learning:** This Flutter application frequently uses `IconButton` for navigation (Back) and password toggling (Show/Hide) without providing the `tooltip` property. This causes an accessibility issue as screen readers cannot announce the button's purpose, and desktop/web users don't get hover context.
**Action:** Always include a descriptive `tooltip` property on `IconButton` and other icon-only interactive widgets (e.g., `tooltip: 'Show password'`) to ensure full semantic labeling and hover support across all platforms.

## 2026-08-25 - Improve Contrast on Destructive Actions
**Learning:** Destructive actions with a `backgroundColor: Colors.red` on `ElevatedButton` might not have sufficient text contrast if the foregroundColor is not explicitly set, particularly depending on the app theme defaults.
**Action:** Always specify `foregroundColor: Colors.white` when using red backgrounds for warnings/destructive buttons to ensure accessibility and readability.

## 2026-08-26 - Missing tooltips on interactive icon-only buttons
**Learning:** Found an icon-only `IconButton.filled` used for sending chat messages that was missing a tooltip. Icon-only buttons must have tooltips or semantic labels for accessibility, otherwise screen readers won't know what they do.
**Action:** Ensure all `IconButton`, `IconButton.filled`, and `FloatingActionButton` widgets have meaningful `tooltip` properties.

## 2026-08-26 - Missing Semantic Wrappers on Custom Interactive Cards
**Learning:** This Flutter application uses custom interactive widgets like `InkWell` and `GestureDetector` for major navigation flows (e.g., dashboard and role cards). Without explicit accessibility tags, screen readers cannot properly announce these elements as buttons or provide context about their destination.
**Action:** Always wrap the outer `Material`, `InkWell`, or `Card` widget of custom interactive elements acting as buttons in a `Semantics` widget with `button: true`, a clear `label`, and a descriptive `hint` (e.g., `hint: 'Navigate to $title'`) to ensure full accessibility.

## 2026-08-29 - Adding Semantics to GestureDetectors
**Learning:** Found that `GestureDetector` and `InkWell` used for primary actions (like photo upload and date picking) lack inherent accessibility labels in Flutter, making them opaque to screen readers.
**Action:** Always wrap custom touch targets (`GestureDetector`, `InkWell`, etc.) that act as buttons with a `Semantics` widget. Set `button: true`, a clear `label`, and a descriptive `hint` to ensure they are properly announced by accessibility services.
## 2024-05-19 - Improved Empty State for Classwork List
**Learning:** Returning just a plain `Text` widget for empty states looks barren and lacks visual polish. Users appreciate a more pronounced empty state.
**Action:** When a list is empty (e.g., no classwork notes), prefer returning a centered `Column` containing a relevant `Icon` (like `Icons.folder_open` with size 48 and `Colors.grey.shade400`) and the descriptive text below it, rather than just plain grey text.
