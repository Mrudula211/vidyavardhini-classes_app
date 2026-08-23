# AGENTS.md — Coding Rules & Guidelines for Jules / AI Agents

This file contains coding rules, conventions, architectural patterns, and guidelines for AI agents (including Jules) working on the **Vidyavardhini Classes App**.

---

## 1. General Rules
- **Architecture & Style:** Follow the existing project architecture (Riverpod + Repository pattern + Supabase) and Dart coding style.
- **Scope Control:** Do not modify unrelated files or functionality. Keep changes strictly focused on the requested task.
- **Preserve Functionality:** Maintain existing features and behavior unless the task explicitly calls for changes.
- **Dependencies:** Do not add unnecessary third-party dependencies to `pubspec.yaml` without explicit approval.
- **Authentication & Security:** Preserve existing authentication logic, role permissions (Admin, Teacher, Student), and safety guards (e.g., student approval status flow, admin access control).

---

## 2. Testing & Refactoring Conventions
- **Constructor Injection:** Always allow `SupabaseClient` to be injected via repository constructors (e.g., `RepositoryName({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;`) to support unit testing without requiring a live database connection.
- **Mocking Library:** Use `mocktail` for unit testing Supabase client calls.
- **Test Structure:** Mirror the `lib/` directory structure in the `test/` directory (e.g., `test/features/admin/students/repository/student_repository_test.dart`).
- **Run Tests & Analyzer:** Always verify that `flutter analyze` passes and unit tests execute cleanly before completing a task.

---

## 3. Emoji Rules (Strict Prohibition)
- **Source Code:** Do NOT use emojis anywhere in source code.
- **Identifiers & Text:** Do NOT add emojis to comments, variable names, function names, class names, string literals, UI text, logs, error messages, or documentation inside the source code unless explicitly requested.
- **Commits & PRs:** Do NOT use emojis in commit messages, branch names, or pull request descriptions unless explicitly requested.
- **Professional Tone:** Keep all code, comments, logs, developer-facing text, and user-facing UI clean, professional, and readable.

---

## 4. UI & Design System Rules
- **No Decorative Emojis:** Do not add decorative emojis to the application's user interface.
- **Design System Consistency:** Follow existing design system tokens, spacing, typography (Cinzel for headings, Poppins for body text), and component patterns.
- **Component Reuse:** Reuse existing widgets and shared components whenever possible. Do not introduce new UI patterns when an existing project pattern can be reused.
- **No Hardcoded Colors:** Use Theme colors (`Theme.of(context).colorScheme`) or defined app theme constants instead of hardcoding random hex values.
- **Frontend vs Backend Scoping:** Do not modify backend code or database schemas when only asked for frontend UI changes.

---

## 5. Accessibility Rules
- **Accessibility Preservation:** Preserve and improve accessibility when creating or modifying UI components.
- **Semantic Labels:** Provide meaningful `semanticLabel` and `tooltip` properties for icon-only buttons (`IconButton`, `FloatingActionButton`).
- **No Emoji Replacements:** Do not replace proper accessibility text or icons with emojis or decorative characters.

---

## 6. Code Hygiene & Best Practices
- **No `print()`:** Do not use `print()` statements in production code. Use `debugPrint()` or structured logging utilities if needed.
- **Clean Imports:** Keep imports clean and organized; remove unused imports.
- **Preserve Documentation:** Retain existing docstrings and code comments unless explicitly instructed to update them.

---

## 7. Pre-Submission Checklist (Before Finishing Task)
- [ ] Review all modified files for unintended changes or scope drift.
- [ ] Ensure no emojis were introduced into the codebase, comments, or UI text.
- [ ] Verify that `flutter analyze` runs cleanly without new errors or warnings.
- [ ] Run relevant tests (`flutter test`) and confirm all test cases pass.
- [ ] Do not overwrite unrelated changes from `main`.
