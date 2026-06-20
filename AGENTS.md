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
