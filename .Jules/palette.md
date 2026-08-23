## 2023-10-24 - Missing tooltips on icon-only buttons
**Learning:** Found an accessibility issue pattern across this app's UI components: many icon-only buttons (`IconButton`) were missing the `tooltip` property, which acts as the semantic label for screen readers.
**Action:** Always include a descriptive `tooltip` attribute on `IconButton` and other icon-only components to ensure accessibility and better user experience for keyboard/screen reader users.
