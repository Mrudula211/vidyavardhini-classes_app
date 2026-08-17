## 2024-05-18 - Added Tooltips to Auth Screen IconButtons
**Learning:** Found several missing tooltips on `IconButton` widgets in authentication screens (`admin_login_screen.dart`, `phone_entry_screen.dart`), especially for back navigation and dynamic state icons like password visibility toggle. Since these are icon-only, screen readers will read them poorly.
**Action:** Always verify `IconButton` elements have a descriptive `tooltip` attribute assigned, specifically adapting the text dynamically if the icon represents a stateful toggle (like showing or hiding a password).
