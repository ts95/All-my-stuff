# Database Abstraction Layer — Design Spec

**Date**: 2026-06-21
**Goal**: Abstract SwiftData away from all SwiftUI views so that Previews work without CloudKit, while maintaining reactivity and query capabilities. Use `swift-dependencies` for dependency injection with automatic context detection (`.live`/`.preview`/`.test`).

---

## Problem

All six views in the app import `SwiftData` directly through `@Environment(\.modelContext)` and `@Query`. Because the app uses CloudKit sync, SwiftUI Previews are unreliable — they either fail or require in-memory container workarounds scattered across `PreviewHelper.swift`. Views are tightly coupled to the persistence layer, making testing and previewing difficult.

## Decision

**Option A — `@Observable` Store + swift-dependencies**: Per-entity `@Observable` stores injected via `@Dependency(\.)` from the `swift-dependencies` library. The library auto-detects context: `.live` uses SwiftData+CloudKit, `.preview` uses mock data (no container), `.test` uses deterministic fixtures. Views depend only on the store — never on SwiftData.

## Architecture

```
Views (SwiftUI, no SwiftData import)
  ↓ depends on
@Dependency(\.itemStore), @Dependency(\.categoryStore), @Dependency(\.locationStore)
  ↓ depends on
DependencyValues (swift-dependencies)
  ↓ resolves to
ItemStore: DependencyKey (liveValue, previewValue, testValue)
CategoryStore: DependencyKey
LocationStore: DependencyKey
  ↓ liveValue depends on
SwiftData Models (Item, ItemCategory, ItemLocation) + ModelContext
```

The only files importing `SwiftData` in the Services layer are the live implementations registered as `DependencyKey.liveValue`.

## Core Components

### 1. `EntityStoreProtocol<Entity>`

Protocol defining the contract between views and the data layer:

```swift
protocol EntityStoreProtocol: Sendable {
    associatedtype Entity: Identifiable & Observable

    var items: [Entity] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func fetchAll() async throws
    func query(_ predicate: @escaping (Entity) -> Bool) async throws -> [Entity]
    func insert(_ entity: Entity) async throws
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func refresh() async throws
}
```

### 2. `@Observable ItemStore` (and `CategoryStore`, `LocationStore`)

Per-entity `@Observable` stores holding reactive state:

- `items: [Entity]` — current dataset, observed by views
- `isLoading: Bool` — loading indicator
- `error: Error?` — last error

Views observe `store.items` reactively through `@Observable`. No `@Query` needed.

### 3. `DependencyKey` Conformances

Each store conforms to `DependencyKey` with three context values:

```swift
extension ItemStore: DependencyKey {
    // Live: wraps SwiftData + CloudKit
    static let liveValue: ItemStore = {
        let context = ModelContainer.mainContext
        return ItemStore(context: context)
    }()

    // Preview: hardcoded sample data, zero SwiftData
    static var previewValue: ItemStore {
        ItemStore.preview()
    }

    // Test: deterministic empty state
    static var testValue: ItemStore {
        ItemStore.test()
    }
}

extension DependencyValues {
    var itemStore: ItemStore {
        get { self[ItemStore.self] }
        set { self[ItemStore.self] = newValue }
    }
}
```

Same pattern for `CategoryStore` and `LocationStore`.

### 4. Live Implementation

The live store wraps `ModelContext`. The **only** code importing `SwiftData` in the Services layer.

- `query(_:)` pushes predicates down to `FetchDescriptor` with `NSPredicate` — efficient server-side filtering
- Registers for `ModelContext` change notifications; on CloudKit sync, refreshes `items` and re-evaluates registered queries
- Calls `modelContext.save()` after mutations

### 5. Preview Implementation

Returns hardcoded sample data. Zero SwiftData dependency. Used automatically in Xcode Previews via `previewValue`.

- `query(_:)` filters the in-memory array — simple, fast
- `insert`/`save`/`delete` mutate the in-memory array
- No async overhead — all operations complete immediately
- Sample data includes items with categories, locations, and prices for realistic previews

### 6. Test Implementation

Deterministic empty state. Used automatically in Swift Testing via `testValue`.

- All queries return empty arrays by default
- Tests override with `withDependencies { $0.itemStore = ... }` when needed

## Query Model

### Live Store — Predicate Pushdown

```swift
// View calls:
let electronics = await store.query { $0.categories.contains("Electronics") }

// Live store translates to:
let desc = FetchDescriptor<Item>(predicate: NSPredicate(...))
return try context.fetch(desc)
```

### Preview/Test Store — In-Memory Filter

```swift
func query(_ predicate: @escaping (Entity) -> Bool) -> [Entity] {
    items.filter(predicate)
}
```

### Grouping

`ItemListView`'s category/location grouping logic moves into the store as a `grouped(by:)` method:

```swift
let grouped = store.grouped(by: \Item.categories)
// Returns [(group: ItemCategory, items: [Item])]
```

## Data Flow

**Before:**
```
View → @Environment(\.modelContext) → SwiftData directly
View → @Query → SwiftData directly
```

**After:**
```
View → @Dependency(\.itemStore) → ItemStore
  → .items (reactive array, via @Observable)
  → .query { ... } (filtered reactive results)
  → .save() / .delete() (async mutations)
```

### Reactivity

- Views observe `store.items` — updates propagate through `@Observable`
- Live store registers for `ModelContext` change notifications; on CloudKit sync, it refreshes `items` and re-evaluates registered queries
- Preview/test store mutations update the in-memory array immediately

### Context Auto-Detection

The `swift-dependencies` library detects context automatically:

| Context | Trigger | Store Used |
|---------|---------|------------|
| `.live` | Normal app run (simulator/device) | SwiftData + CloudKit |
| `.preview` | Xcode Previews (`XCODE_RUNNING_FOR_PREVIEWS=1`) | Mock data, no container |
| `.test` | Swift Testing / XCTest runs | Deterministic fixtures |

No manual wiring needed. Previews just work.

### Previews

```swift
#Preview {
    ContentView()
    // No .environment(), no .modelContainer(), no container setup
    // swift-dependencies auto-resolves to previewValue
}
```

No container setup. No async initialization. Instant preview.

## Migration Plan

### Phase 1: Foundation
1. Create `EntityStoreProtocol<Entity>` protocol
2. Create `ItemStore` with `DependencyKey` conformance (live + preview + test values)
3. Create `CategoryStore` with `DependencyKey` conformance
4. Create `LocationStore` with `DependencyKey` conformance
5. Register all stores in `DependencyValues` extensions
6. Call `prepareDependencies` in `All_my_stuffApp.init()` to initialize live stores

### Phase 2: View Migration
7. Migrate `ItemListView` — replace `@Query` with `@Dependency(\.itemStore)` and `store.items`
8. Migrate `ContentView` — replace `modelContext.insert()` with `store.insert()`
9. Migrate `ItemFormSheet` — replace `modelContext.save()` with `store.save()`
10. Migrate `ItemProfileView` — replace `modelContext.delete()` with `store.delete()`
11. Migrate `CategoryPickerView` — replace `@Query` and `modelContext.insert()` with store
12. Migrate `LocationPickerView` — replace `@Query` and `modelContext.insert()` with store

### Phase 3: Cleanup
13. Remove `import SwiftData` from all view files
14. Update `PreviewHelper.swift` — remove in-memory container helpers, previews use `previewValue` automatically
15. Update tests to use `withDependencies` for store overrides
16. Update `AGENTS.md` with new conventions

## Testing Strategy

- **Unit tests**: `testValue` provides deterministic state. Override with `withDependencies { $0.itemStore = ... }` for specific scenarios. No container setup.
- **Integration tests**: Override with `liveValue` using in-memory `ModelContainer` to verify SwiftData operations.
- **View previews**: `previewValue` provides sample data automatically. Zero setup code.

```swift
@Test func deleteItemRemovesFromStore() async throws {
    await withDependencies {
        $0.itemStore = ItemStore.preview() // or custom test fixture
    } operation: {
        let store = Dependency(\.itemStore).wrappedValue
        try await store.delete(store.items[0])
        #expect(store.items.count == 0)
    }
}
```

## Files Affected

| File | Change |
|------|--------|
| `Services/EntityStoreProtocol.swift` | New — protocol definition |
| `Services/ItemStore.swift` | New — `@Observable` store + `DependencyKey` conformance |
| `Services/CategoryStore.swift` | New — `@Observable` store + `DependencyKey` conformance |
| `Services/LocationStore.swift` | New — `@Observable` store + `DependencyKey` conformance |
| `Services/DependencyRegistration.swift` | New — `DependencyValues` extensions + `prepareDependencies` |
| `All my stuff/All_my_stuffApp.swift` | Add `prepareDependencies` in `init()` |
| `Views/ContentView.swift` | Replace `modelContext` with `@Dependency(\.itemStore)` |
| `Views/ItemListView.swift` | Replace `@Query` with `@Dependency(\.itemStore)` |
| `Views/ItemFormSheet.swift` | Replace `modelContext` with `@Dependency(\.itemStore)` |
| `Views/ItemProfileView.swift` | Replace `modelContext` with `@Dependency(\.itemStore)` |
| `Views/CategoryPickerView.swift` | Replace `@Query` + `modelContext` with `@Dependency` |
| `Views/LocationPickerView.swift` | Replace `@Query` + `modelContext` with `@Dependency` |
| `Services/PreviewHelper.swift` | Remove in-memory container helpers |
| `All my stuffTests/` | Update tests to use `withDependencies` |
| `AGENTS.md` | Add new conventions |
