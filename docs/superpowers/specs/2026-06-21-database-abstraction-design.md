# Database Abstraction Layer — Design Spec

**Date**: 2026-06-21
**Goal**: Abstract SwiftData away from all SwiftUI views so that Previews work without CloudKit, while maintaining reactivity and query capabilities.

---

## Problem

All six views in the app import `SwiftData` directly through `@Environment(\.modelContext)` and `@Query`. Because the app uses CloudKit sync, SwiftUI Previews are unreliable — they either fail or require in-memory container workarounds scattered across `PreviewHelper.swift`. Views are tightly coupled to the persistence layer, making testing and previewing difficult.

## Decision

**Option A — Generic `@Observable` Store + Environment Keys**: A single generic store class parameterized by entity type, exposed via custom `@Environment` keys. Views depend only on the store protocol — never on SwiftData. Previews inject a mock store with hardcoded data.

## Architecture

```
Views (SwiftUI, no SwiftData import)
  ↓ depends on
@Observable DataStore<T> + Environment Keys
  ↓ depends on
DataStoreProtocol<T>
  ↓ implemented by
LiveStore<T> (wraps SwiftData) / MockStore<T> (hardcoded data)
  ↓ depends on
SwiftData Models (Item, ItemCategory, ItemLocation)
```

`LiveStore` is the only file in the Services layer that imports `SwiftData`.

## Core Components

### 1. `DataStoreProtocol<T>`

Protocol defining the contract between views and the data layer:

```swift
protocol DataStoreProtocol: AnyObject {
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

### 2. `@Observable DataStore<T>`

Generic observable store holding reactive state:

- `items: [T]` — current dataset, observed by views
- `isLoading: Bool` — loading indicator
- `error: Error?` — last error

Views observe `store.items` reactively through `@Observable`. No `@Query` needed.

### 3. `LiveStore<T>`

Concrete implementation wrapping `ModelContext`. The **only** file importing `SwiftData` in the Services layer.

- `query(_:)` pushes predicates down to `FetchDescriptor` with `NSPredicate` — efficient server-side filtering
- Maintains a query registry: when CloudKit syncs or data mutates, registered queries re-evaluate and update reactive state
- Calls `modelContext.save()` after mutations

### 4. `MockStore<T>`

Returns hardcoded sample data. Zero SwiftData dependency. Used in Previews and unit tests.

- `query(_:)` filters the in-memory array — simple, fast
- `insert`/`save`/`delete` mutate the in-memory array
- No async overhead — all operations are synchronous

### 5. Environment Keys

Custom `@Environment` keys per entity type:

```swift
extension EnvironmentValues {
    var itemsStore: DataStoreProtocol<Item> { ... }
    var categoriesStore: DataStoreProtocol<ItemCategory> { ... }
    var locationsStore: DataStoreProtocol<ItemLocation> { ... }
}
```

Views access stores via `@Environment(\.itemsStore)`.

## Query Model

### Live Store — Predicate Pushdown

```swift
// View calls:
let electronics = await store.query { $0.categories.contains("Electronics") }

// LiveStore translates to:
let desc = FetchDescriptor<Item>(predicate: NSPredicate(...))
return try context.fetch(desc)
```

### Mock Store — In-Memory Filter

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
View → @Environment(\.itemsStore) → DataStore<Item>
  → .items (reactive array)
  → .query { ... } (filtered reactive results)
  → .save() / .delete() (async mutations)
```

### Reactivity

- Views observe `store.items` — updates propagate through `@Observable`
- `LiveStore` registers for `ModelContext` change notifications; on CloudKit sync, it refreshes `items` and re-evaluates registered queries
- `MockStore` mutations update the in-memory array immediately

### Previews

```swift
#Preview {
    ContentView()
        .environment(\.itemsStore, MockItemStore())
        .environment(\.categoriesStore, MockCategoryStore())
        .environment(\.locationsStore, MockLocationStore())
}
```

No container setup. No async initialization. Instant preview.

## Migration Plan

### Phase 1: Foundation
1. Create `DataStoreProtocol<T>`
2. Create `LiveStore<T>` wrapping SwiftData
3. Create `MockStore<T>` with sample data
4. Create environment keys for each entity type

### Phase 2: View Migration
5. Migrate `ItemListView` — replace `@Query` with `store.items` and `store.query`
6. Migrate `ContentView` — replace `modelContext.insert()` with `store.insert()`
7. Migrate `ItemFormSheet` — replace `modelContext.save()` with `store.save()`
8. Migrate `ItemProfileView` — replace `modelContext.delete()` with `store.delete()`
9. Migrate `CategoryPickerView` — replace `@Query` and `modelContext.insert()`
10. Migrate `LocationPickerView` — replace `@Query` and `modelContext.insert()`

### Phase 3: Cleanup
11. Remove `import SwiftData` from all view files
12. Update `PreviewHelper.swift` to use mock stores
13. Update tests to inject mock stores where appropriate
14. Update `AGENTS.md` with new conventions

## Testing Strategy

- **Unit tests**: `MockStore` provides deterministic data — no container setup needed
- **Integration tests**: `LiveStore` with in-memory container verifies SwiftData operations
- **View previews**: Mock stores, instant load, no CloudKit dependency

## Files Affected

| File | Change |
|------|--------|
| `Services/DataStoreProtocol.swift` | New — protocol definition |
| `Services/DataStore.swift` | New — generic `@Observable` store |
| `Services/LiveStore.swift` | New — SwiftData-backed implementation |
| `Services/MockStore.swift` | New — mock implementation for previews |
| `Services/EnvironmentKeys.swift` | New — `@Environment` key extensions |
| `Views/ContentView.swift` | Replace `modelContext` with store |
| `Views/ItemListView.swift` | Replace `@Query` with store |
| `Views/ItemFormSheet.swift` | Replace `modelContext` with store |
| `Views/ItemProfileView.swift` | Replace `modelContext` with store |
| `Views/CategoryPickerView.swift` | Replace `@Query` + `modelContext` with store |
| `Views/LocationPickerView.swift` | Replace `@Query` + `modelContext` with store |
| `Services/PreviewHelper.swift` | Update to use mock stores |
| `AGENTS.md` | Add new conventions |
