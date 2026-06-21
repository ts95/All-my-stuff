# Skill: swift-dependencies

# Swift Dependencies

Register, inject, and override dependencies using Point-Free's `swift-dependencies` library. Covers `DependencyKey`, `TestDependencyKey`, `@Dependency`, `DependencyValues`, `withDependencies`, `prepareDependencies`, context auto-detection (`.live`/`.preview`/`.test`), SwiftUI integration, and escaping closure propagation.

## Contents

- [Core Concepts](#core-concepts)
- [Registering Dependencies](#registering-dependencies)
- [Accessing Dependencies](#accessing-dependencies)
- [Context Auto-Detection](#context-auto-detection)
- [Overriding Dependencies](#overriding-dependencies)
- [SwiftUI Integration](#swiftui-integration)
- [Escaping Closures](#escaping-closures)
- [Testing](#testing)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)

## Core Concepts

The library uses `@TaskLocal` to thread dependencies through the call stack. Three contexts are auto-detected:

| Context | When | Uses |
|---------|------|------|
| `.live` | Simulator/device, normal run | `DependencyKey.liveValue` |
| `.preview` | Xcode Previews (`XCODE_RUNNING_FOR_PREVIEWS=1`) | `TestDependencyKey.previewValue` |
| `.test` | XCTest/Swift Testing runs | `TestDependencyKey.testValue` |

Override any context with the `SWIFT_DEPENDENCIES_CONTEXT` environment variable.

## Registering Dependencies

**Step 1:** Define the dependency interface and conform to `DependencyKey`:

```swift
struct ItemClient: Sendable {
    var fetchAll: () async throws -> [Item]
    var save: (Item) async throws -> Void
    var delete: (Item) async throws -> Void
}

extension ItemClient: DependencyKey {
    // Live: real implementation
    static let liveValue = Self(
        fetchAll: { /* network or persistence call */ },
        save: { /* persist */ },
        delete: { /* remove */ }
    )

    // Preview: sample data, no side effects
    static var previewValue: Self {
        Self(
            fetchAll: { [Item(name: "Laptop"), Item(name: "Phone")] },
            save: { _ in },
            delete: { _ in }
        )
    }

    // Test: deterministic, no side effects
    static var testValue: Self {
        Self(
            fetchAll: { [] },
            save: { _ in },
            delete: { _ in }
        )
    }
}
```

**Step 2:** Register in `DependencyValues`:

```swift
extension DependencyValues {
    var itemClient: ItemClient {
        get { self[ItemClient.self] }
        set { self[ItemClient.self] = newValue }
    }
}
```

**Interface/Implementation Separation:** Conform to `TestDependencyKey` in the interface module and `DependencyKey` in the implementation module:

```swift
// Interface module
extension ItemClient: TestDependencyKey {
    static var testValue: Self { /* mock */ }
    static var previewValue: Self { /* sample data */ }
}

// Implementation module
extension ItemClient: DependencyKey {
    static let liveValue = Self(/* real impl */)
}
```

## Accessing Dependencies

Use `@Dependency` property wrapper anywhere — classes, structs, functions:

```swift
@Observable
final class ItemStore {
    @ObservationIgnored
    @Dependency(\.itemClient) var itemClient

    func loadItems() async throws {
        items = try await itemClient.fetchAll()
    }
}

// In a free function
func deleteItem(_ item: Item) async throws {
    @Dependency(\.itemClient) var client
    try await client.delete(item)
}
```

**Rules:**
- Never use `@Dependency` on `static` properties — they lazily capture and won't reflect overrides
- Always mark `@ObservationIgnored` when used inside `@Observable` classes
- Accessing a dependency caches its value for the current context

## Context Auto-Detection

The library detects context automatically:

```swift
// In live app → uses liveValue
// In Xcode Preview → uses previewValue
// In tests → uses testValue
@Dependency(\.itemClient) var client
```

Override context manually:

```swift
withDependencies {
    $0.context = .preview
} operation: {
    // All dependencies resolve to previewValue
}
```

## Overriding Dependencies

**Scoped override (synchronous):**

```swift
withDependencies {
    $0.itemClient.fetchAll = { [Item(name: "Test")] }
} operation: {
    // Uses overridden fetchAll
}
// Original dependency restored after scope
```

**Scoped override (asynchronous):**

```swift
await withDependencies {
    $0.itemClient = .mock
} operation: {
    // Uses mock for entire async scope, propagates to Tasks
}
```

**Override all dependencies:**

```swift
withDependencies { $0 = .live } operation: {
    // All dependencies use live values
}

withDependencies { $0 = .test } operation: {
    // All dependencies use test values
}
```

**Prepare at app launch (global, one-time):**

```swift
@main
struct MyApp: App {
    init() {
        prepareDependencies {
            $0.itemClient = LiveItemClient(/* config */)
        }
    }
}
```

In Previews, use `let _` to avoid result builder conflicts:

```swift
#Preview {
    let _ = prepareDependencies {
        $0.itemClient = PreviewItemClient()
    }
    ContentView()
}
```

## SwiftUI Integration

**Thread dependencies through view hierarchy:**

```swift
ContentView()
    .dependency(\.itemClient, mockClient)
```

At the Scene level:

```swift
WindowGroup {
    ContentView()
}
.dependency(\.itemClient, liveClient)
```

**Using `@Dependency` in views:**

```swift
struct ItemView: View {
    @Dependency(\.itemClient) var itemClient

    var body: some View {
        Button("Delete") {
            Task { try await itemClient.delete(item) }
        }
    }
}
```

`@Dependency` conforms to `DynamicProperty` in SwiftUI, so it updates automatically when the environment changes.

## Escaping Closures

Dependencies do NOT propagate across escaping closures. Use `withEscapedDependencies`:

```swift
withEscapedDependencies { dependencies in
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        dependencies.yield {
            @Dependency(\.itemClient) var client
            // Uses dependencies captured at withEscapedDependencies call site
        }
    }
}
```

Dependencies DO propagate across `Task` boundaries (structured concurrency).

## Testing

**Override in Swift Testing:**

```swift
@Test func deleteItemRemovesFromList() async throws {
    await withDependencies {
        $0.itemClient.fetchAll = { [Item(name: "A"), Item(name: "B")] }
        $0.itemClient.delete = { _ in }
    } operation: {
        let store = ItemStore()
        try await store.loadItems()
        #expect(store.items.count == 2)
        try await store.delete(store.items[0])
        // Verify behavior
    }
}
```

**Override in XCTest:**

```swift
func testDeleteItem() {
    withDependencies {
        $0.itemClient = .mock
    } operation: {
        // Test with mock
    }
}
```

**Default test value:** Implement `testValue` on the dependency key to provide a default for all tests. Unimplemented `testValue` triggers a test failure when accessed.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `@Dependency` on `static` properties | Use instance properties only |
| Forgetting `@ObservationIgnored` in `@Observable` classes | Always mark `@ObservationIgnored` |
| Accessing `liveValue` in tests without override | Implement `testValue` or use `withDependencies` |
| Expecting dependencies to propagate across escaping closures | Use `withEscapedDependencies` |
| Calling `prepareDependencies` after dependency was accessed | Call as early as possible in app lifecycle |
| Preparing the same dependency key twice | Each key can be prepared exactly once |
| Forgetting `Sendable` on dependency types | All dependency values must be `Sendable` |

## Review Checklist

- [ ] Dependency types are `Sendable`
- [ ] `DependencyKey` provides `liveValue`, `previewValue`, and `testValue`
- [ ] `DependencyValues` extension registers the dependency with getter and setter
- [ ] `@Dependency` is never used on `static` properties
- [ ] `@ObservationIgnored` is applied when using `@Dependency` in `@Observable` classes
- [ ] Escaping closures use `withEscapedDependencies`
- [ ] `prepareDependencies` called at app entry point, not lazily
- [ ] Tests override dependencies or implement `testValue`

## References

- [swift-dependencies on GitHub](https://github.com/pointfreeco/swift-dependencies)
- [Registering Dependencies](https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/registeringdependencies)
- [Live/Preview/Test Contexts](https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/livepreviewtest)
- [Lifetimes](https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies/lifetimes)
