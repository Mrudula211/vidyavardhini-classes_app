## 2024-07-24 - Missing Semantic Labels on Icon Buttons
**Learning:** This Flutter application frequently uses `IconButton` for navigation (Back) and password toggling (Show/Hide) without providing the `tooltip` property. This causes an accessibility issue as screen readers cannot announce the button's purpose, and desktop/web users don't get hover context.
**Action:** Always include a descriptive `tooltip` property on `IconButton` and other icon-only interactive widgets (e.g., `tooltip: 'Show password'`) to ensure full semantic labeling and hover support across all platforms.

## 2026-08-26 - Missing Semantic Wrappers on Custom Interactive Cards
**Learning:** This Flutter application uses custom interactive widgets like `InkWell` and `GestureDetector` for major navigation flows (e.g., dashboard and role cards). Without explicit accessibility tags, screen readers cannot properly announce these elements as buttons or provide context about their destination.
**Action:** Always wrap the outer `Material`, `InkWell`, or `Card` widget of custom interactive elements acting as buttons in a `Semantics` widget with `button: true`, a clear `label`, and a descriptive `hint` (e.g., `hint: 'Navigate to $title'`) to ensure full accessibility.
