# AGENTS.md

## Tooling: Prefer Xcode MCP

**Always use the Xcode MCP tools** for any operation that touches the Xcode project. They understand the project structure, handle file references in `.pbxproj`, and provide accurate diagnostics. Generic tools (bash `grep`/`find`, filesystem `read`/`edit`) bypass Xcode's file indexing and can produce stale results or orphan files from the project.

| Task | Use Xcode MCP | Not |
|------|--------------|-----|
| Browse project structure | `xcode_XcodeLS` / `xcode_XcodeGlob` | `ls` / `find` |
| Read a source file | `xcode_XcodeRead` | `cat` / `read` |
| Edit a source file | `xcode_XcodeUpdate` | `sed` / `edit` |
| Create a new file | `xcode_XcodeWrite` | `echo >` / `write` |
| Move / rename a file | `xcode_XcodeMV` | `git mv` / `mv` |
| Delete a file | `xcode_XcodeRM` | `git rm` / `rm` |
| Create a directory | `xcode_XcodeMakeDir` | `mkdir` |
| Check compiler issues | `xcode_XcodeRefreshCodeIssuesInFile` | — |
| Build the app | `xcode_BuildProject` | `xcodebuild` |
| Run tests | `xcode_RunAllTests` / `xcode_RunSomeTests` | `xcodebuild build-for-testing` |
| Get test list | `xcode_GetTestList` | — |
| Render a SwiftUI preview | `xcode_RenderPreview` | — |

Only fall back to generic tools when the Xcode MCP cannot express what you need (e.g., inspecting non-project files like `AGENTS.md`, running `git` commands, or reading build logs with `xcode_GetBuildLog`).

### Known Issues

- **LSP errors are false positives**: Xcode's language server reports "Cannot find type" and "No such module" errors across all files. These do not affect the build — always verify with `xcode_BuildProject` before treating a diagnostic as real.

## Build & Test

- **Build**: `xcode_BuildProject` on the active scheme
- **Preview**: `xcode_RenderPreview` on any SwiftUI view file
- **Run tests**: `xcode_RunAllTests` for the active scheme's test plan; `xcode_RunSomeTests` for targeted tests

## Conventions

### Code Style

- SwiftUI-first, declarative UI — no UIKit/AppKit unless explicitly required
- Files named after the primary type they contain (e.g., `Item.swift` contains `Item`)
- One primary declaration per file where possible

### Architecture

- **Models/** — SwiftData `@Model` classes and supporting enums/structs
- **Views/** — SwiftUI views, organized by screen/responsibility
- **Services/** — Business logic, image handling, utilities

### Important Rules

1. **No external dependencies** unless explicitly approved by the owner
2. **SwiftData model changes require coordination**: when adding/removing a `@Model` property, update all related views in the same change
3. **Adaptive layouts first**: always prefer `NavigationSplitView`, size class adaptations, and responsive design that works on iPhone, iPad, and Mac without device-specific branches
4. **No orphaned model properties**: every model field must be surfaced in at least one view
5. For Swift Package Manager types, SwiftData properties require a non-empty `description` parameter
6. **Never use git worktrees** — the Xcode MCP can only operate on the repository where `.xcodeproj` lives; worktrees break file discovery and tool access. Work directly on feature branches instead.
7. **SwiftData iOS 26 breaking changes**: `ModelContext(.inMemory())` removed — use `Schema` + `ModelConfiguration(isStoredInMemoryOnly: true)` instead; `context.insert()` is not variadic — call it once per object; `context.count(for:)` removed — use `try context.fetchCount(FetchDescriptor<T>())`
8. **Navigation**: Always use `NavigationStack` with `NavigationPath` + `.navigationDestination(for:)` for push navigation — never `NavigationLink(destination:)`. On iPhone, `NavigationSplitView` collapses to single-column, so the list must be wrapped in a `NavigationStack` with a bound `NavigationPath` to support detail view push navigation. Track selected item separately for the split-view detail column and sync it with the path.

## Installed Skills

The following skills are available in `.agents/skills/` — invoke the relevant one before working on matching tasks:

| Skill | When to Use |
|-------|-------------|
| `swiftui-patterns` | Structuring SwiftUI apps, @Observable state management, view composition, environment wiring, async loading, iOS 26+ APIs, performance |
| `swiftui-navigation` | NavigationStack, NavigationSplitView, sheet presentation, tab navigation, deep linking, programmatic routing |
| `swiftui-layout-components` | Stacks, grids, lists with sections/swipe actions, scroll views, forms, pickers, .searchable, overlays |
| `swiftdata` | @Model definitions, @Query/#Predicate/FetchDescriptor, ModelContainer/ModelContext setup, schema migrations, CloudKit sync config |
| `cloudkit` | CKContainer/CKRecord/CKQuery, CKSyncEngine, conflict resolution, iCloud key-value storage, SwiftData CloudKit integration |
| `swift-concurrency` | Sendable conformance, actor isolation, structured concurrency, @concurrent, nonisolated(nonsending), Swift 6 strict concurrency |
| `swift-testing` | Swift Testing framework: @Test/@Suite, #expect/#require, confirmation, mocking, XCTest migration, test organization |
| `swift-architecture` | Choosing MV/MVVM/MVI/TCA/Clean Architecture, evaluating architecture fit, migrating patterns |
| `swift-language` | Modern Swift idioms: if/switch expressions, typed throws, property wrappers, opaque/existential types, Codable, Regex builders, collection APIs |
| `swift-api-design-guidelines` | Naming conventions, argument labels, documentation comments, protocol naming, call site clarity |
