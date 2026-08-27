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

## 2026-08-26 - Unlabeled Form Inputs in Registration
**Learning:** In Flutter, using `GestureDetector` over `AbsorbPointer` to create custom select fields (like Date of Birth picker or Photo picker) hides the input's purpose from screen readers because there's no native button semantics.
**Action:** When using `GestureDetector` or `InkWell` to trigger dialogs (like date pickers or image pickers) within a form, ALWAYS wrap them in a `Semantics` widget with `button: true`, a descriptive `label`, and `hint`.

## 2026-08-26 - Missing Tooltips on FloatingActionButtons
**Learning:** While `FloatingActionButton.extended` has a visible text label, it lacks hover support on desktop/web out of the box unless a `tooltip` is explicitly provided.
**Action:** Always provide a `tooltip` string to `FloatingActionButton` and `FloatingActionButton.extended` widgets to ensure consistent cross-platform accessibility and hover context.
