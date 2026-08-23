# 30 Coding Standards

## Purpose
Establishes the rules for writing clean, consistent, and maintainable Flutter/Dart code in this project.

## Dart & Flutter Rules
1. **Lints:** Strict adherence to `flutter_lints`. Run `flutter analyze` locally before committing. No warnings permitted.
2. **Immutability:** Use `const` constructors wherever possible to optimize widget rebuilds. All data models must use `freezed` and be immutable.
3. **Null Safety:** Strict null safety must be maintained. Avoid the `!` operator unless absolutely certain (e.g., immediately after a null check). Prefer `??` fallbacks.
4. **File Naming:** `snake_case.dart` for files, `PascalCase` for classes.
5. **Widget Structure:** Keep the `build` method clean. If it exceeds 100 lines, extract sub-trees into separate private `_StatelessWidget` classes rather than helper methods to leverage Flutter's element tree diffing optimization.

## State Management (Riverpod)
1. **Generators:** Always use `@riverpod` annotations and `build_runner`. Do not write `Provider` or `StateNotifierProvider` manually.
2. **Ref Watching:** Watch providers as high up the widget tree as necessary, but no higher. Use `ref.watch` in the `build` method, and `ref.read` in callbacks (e.g., `onPressed`).
3. **Async Data:** Always handle `AsyncValue` fully (`data`, `loading`, `error`). Do not blindly unwrap `value`.

## Architecture & Layers
1. **No UI in Repositories:** Repository classes should not depend on `flutter/material.dart` and should return raw data or throw custom exceptions.
2. **No Data Fetching in UI:** Widgets should not directly call Supabase. They must interact with a Riverpod provider.
3. **Theme Variables:** Never hardcode colors (e.g., `Colors.red`). Always use `AppColors.error` or `Theme.of(context).colorScheme.error`.

## Cross-References
- [03_ARCHITECTURE.md](../01_overview/03_ARCHITECTURE.md)
- [32_AI_DEVELOPMENT_GUIDELINES.md](32_AI_DEVELOPMENT_GUIDELINES.md)
