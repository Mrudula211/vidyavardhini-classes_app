# 32 AI Development Guidelines

## Purpose
Specific instructions and context designed for AI agents (like Claude/Jules) tasked with modifying or extending this codebase.

## Core Directives for AI Agents
1. **Read Before Acting:** Always read this entire `docs/project_reference/` directory (starting with `01_PROJECT_OVERVIEW.md` and `03_ARCHITECTURE.md`) before writing any code to understand context, theming, and architecture.
2. **Strict File Operations:** Use `write_file`, `replace_with_git_merge_diff`, or bash commands carefully. Ensure you are targeting the correct files in the `lib/` directory according to the feature-first folder structure.
3. **No Artifact Editing:** Never edit files inside `.dart_tool/`, `build/`, `android/`, `ios/`, or generated files (`*.g.dart`, `*.freezed.dart`). If a generated file needs updating, modify the source `.dart` file and run `dart run build_runner build --delete-conflicting-outputs` in the bash session.
4. **Follow the Roadmap:** Do not hallucinate or invent features outside the scope defined in `22_IMPLEMENTATION_BACKLOG.md` and the PRD.
5. **Code Generation:** When generating Riverpod providers, ALWAYS use `@riverpod` syntax. When creating data classes, ALWAYS use `freezed` and `json_serializable`.
6. **Testing as Default:** If implementing a new complex logic block, write a corresponding unit test in `test/` without being explicitly asked.
7. **Security First:** Do not bypass RLS. Do not hardcode secrets. Respect the business rules outlined in `28_BUSINESS_RULES.md`.

## Context Retrieval Tips
- To understand how the UI should look, reference the files in `docs/UI/`.
- To understand the database structure, reference `docs/DATABASE_SCHEMA.md` and the dictionary in `23_DATABASE_DICTIONARY.md`.
- To understand how routing works, look at `lib/core/router/app_router.dart` and `08_NAVIGATION.md`.

## Cross-References
- All files in the `docs/project_reference/` directory.
