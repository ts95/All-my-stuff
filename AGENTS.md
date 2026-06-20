# AGENTS.md

## Build & Test

- **Build**: Open `All my stuff.xcodeproj` in Xcode and build with the active scheme
- **Preview**: Use Xcode Canvas previews on any SwiftUI view file
- **Run tests**: Use Xcode test runner (`Cmd+U`) for `All my stuffTests` target

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
