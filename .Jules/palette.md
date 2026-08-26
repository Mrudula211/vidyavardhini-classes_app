## 2024-07-24 - Missing Semantic Labels on Icon Buttons
**Learning:** This Flutter application frequently uses `IconButton` for navigation (Back) and password toggling (Show/Hide) without providing the `tooltip` property. This causes an accessibility issue as screen readers cannot announce the button's purpose, and desktop/web users don't get hover context.
**Action:** Always include a descriptive `tooltip` property on `IconButton` and other icon-only interactive widgets (e.g., `tooltip: 'Show password'`) to ensure full semantic labeling and hover support across all platforms.
## 2026-08-26 - Missing tooltips on interactive icon-only buttons
**Learning:** Found an icon-only `IconButton.filled` used for sending chat messages that was missing a tooltip. Icon-only buttons must have tooltips or semantic labels for accessibility, otherwise screen readers won't know what they do.
**Action:** Ensure all `IconButton`, `IconButton.filled`, and `FloatingActionButton` widgets have meaningful `tooltip` properties.
