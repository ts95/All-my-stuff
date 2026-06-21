# Database Abstraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Abstract SwiftData away from all SwiftUI views using `@Observable` stores injected via `swift-dependencies`, so Previews work without CloudKit or container setup.

**Architecture:** Per-entity `@Observable` stores (`ItemStore`, `CategoryStore`, `LocationStore`) conform to `DependencyKey` with `liveValue` (SwiftData + CloudKit), `previewValue` (mock data), and `testValue` (deterministic fixtures). Views inject stores via `@Dependency(\.)`. Only the Services layer imports `SwiftData`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, swift-dependencies v1.14.1, `@Observable`, `@Bindable`

## Global Constraints

- iOS 26+ target: `ModelContext(.inMemory())` removed — use `Schema` + `ModelConfiguration(isStoredInMemoryOnly: true)`
- No `import SwiftData` in any View file after migration
- Never use `@Dependency` on `static` properties
- Always mark `@ObservationIgnored` when using `@Dependency` inside `@Observable` classes
- All dependency types must be `Sendable`
- Previews must work with zero setup — no `.modelContainer()`, no in-memory containers
- LSP errors are false positives — always verify with `xcode_BuildProject`
- Existing integration tests in `All my stuffTests/Integration/` test SwiftData directly and should remain unchanged
- Models (`Item`, `ItemCategory`, `ItemLocation`) remain `@Model` classes — no changes to model definitions

---

### Task 1: EntityStoreProtocol

**Files:**
- Create: `All my stuff/Services/EntityStoreProtocol.swift`

**Interfaces:**
- Produces: `EntityStoreProtocol<Entity>` protocol with `items`, `isLoading`, `error`, `fetchAll()`, `query(_:)`, `insert(_:)`, `save(_:)`, `delete(_:)`, `refresh()`, `grouped(by:)`

- [ ] **Step 1: Write the protocol**

```swift
import Foundation

protocol EntityStoreProtocol: Sendable {
    associatedtype Entity: Identifiable

    var items: [Entity] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func fetchAll() async throws
    func query(_ predicate: @escaping @Sendable (Entity) -> Bool) async throws -> [Entity]
    func insert(_ entity: Entity) async throws
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func refresh() async throws
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS (no errors)

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Services/EntityStoreProtocol.swift"
git commit -m "feat: add EntityStoreProtocol defining store contract"
```

---

### Task 2: ItemStore (Protocol + Live + Preview + Test)

**Files:**
- Create: `All my stuff/Services/ItemStore.swift`

**Interfaces:**
- Consumes: `EntityStoreProtocol` from Task 1, `Item`/`ItemCategory`/`ItemLocation` models
- Produces: `ItemStore` class conforming to `EntityStoreProtocol<Item>` and `DependencyKey`

- [ ] **Step 1: Write ItemStore with all three implementations**

```swift
import Foundation
import SwiftData
import SwiftUI
import Dependencies

@Observable
final class ItemStore: EntityStoreProtocol, @unchecked Sendable {
    var items: [Item] = []
    var isLoading: Bool = false
    var error: Error? = nil

    private let context: ModelContext?
    private var notificationToken: NSObjectProtocol?

    init(context: ModelContext) {
        self.context = context
        setupChangeObserver()
    }

    init() {
        self.context = nil
    }

    // MARK: - EntityStoreProtocol

    func fetchAll() async throws {
        guard let context else {
            return
        }
        isLoading = true
        error = nil
        do {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\Item.name, order: .forward)]
            )
            items = try context.fetch(descriptor)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func query(_ predicate: @escaping @Sendable (Item) -> Bool) async throws -> [Item] {
        guard let context else {
            return items.filter(predicate)
        }
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\Item.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        return results.filter(predicate)
    }

    func insert(_ entity: Item) async throws {
        guard let context else {
            items.append(entity)
            return
        }
        context.insert(entity)
        items.append(entity)
    }

    func save(_ entity: Item) async throws {
        guard let context else {
            return
        }
        try context.save()
    }

    func delete(_ entity: Item) async throws {
        guard let context else {
            items.removeAll { $0.id == entity.id }
            return
        }
        context.delete(entity)
        items.removeAll { $0.id == entity.id }
        try context.save()
    }

    func refresh() async throws {
        try await fetchAll()
    }

    // MARK: - Grouping

    func grouped(by keyPath: KeyPath<Item, [ItemCategory]?>) -> [(group: ItemCategory, items: [Item])] {
        var categoryItems: [ItemCategory: [Item]] = [:]
        for item in items {
            if let categories = item[keyPath: keyPath] {
                for category in categories {
                    categoryItems[category, default: []].append(item)
                }
            }
        }
        return categoryItems.map { (group: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group.name < $1.group.name }
    }

    func groupedByLocation() -> [(group: ItemLocation, items: [Item])] {
        var locationItems: [ItemLocation: [Item]] = [:]
        for item in items {
            if let locations = item.locations {
                for location in locations {
                    locationItems[location, default: []].append(item)
                }
            }
        }
        return locationItems.map { (group: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group.name < $1.group.name }
    }

    // MARK: - Factory Methods

    static func live() -> ItemStore {
        let container = ModelContainer.mainContext
        return ItemStore(context: container)
    }

    static func preview() -> ItemStore {
        let store = ItemStore()
        let laptop = Item(name: "Laptop", datePurchased: Date())
        laptop.notes = "2024 MacBook Pro"
        laptop.purchasePrice = 1999.99
        laptop.estimatedValue = 1500

        let headphones = Item(name: "Headphones", datePurchased: Date())
        headphones.notes = "Wireless noise-cancelling"
        headphones.purchasePrice = 349.99

        let phone = Item(name: "Phone", datePurchased: Date())
        phone.notes = "Latest model"
        phone.purchasePrice = 999.99

        let electronics = ItemCategory(name: "Electronics")
        let personal = ItemCategory(name: "Personal")
        let desk = ItemLocation(name: "Desk")
        let bag = ItemLocation(name: "Bag")

        laptop.categories = [electronics]
        laptop.locations = [desk]
        headphones.categories = [electronics, personal]
        headphones.locations = [bag]
        phone.categories = [personal]
        phone.locations = [desk, bag]

        store.items = [laptop, headphones, phone]
        return store
    }

    static func test() -> ItemStore {
        ItemStore()
    }

    // MARK: - Change Observation (Live only)

    private func setupChangeObserver() {
        notificationToken = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ModelContextDidSave"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try await self?.fetchAll()
            }
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS (LSP errors are false positives, trust the build)

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Services/ItemStore.swift"
git commit -m "feat: add ItemStore with live, preview, and test implementations"
```

---

### Task 3: CategoryStore

**Files:**
- Create: `All my stuff/Services/CategoryStore.swift`

**Interfaces:**
- Consumes: `EntityStoreProtocol` from Task 1, `ItemCategory` model
- Produces: `CategoryStore` class conforming to `EntityStoreProtocol<ItemCategory>` and `DependencyKey`

- [ ] **Step 1: Write CategoryStore**

```swift
import Foundation
import SwiftData
import SwiftUI
import Dependencies

@Observable
final class CategoryStore: EntityStoreProtocol, @unchecked Sendable {
    var items: [ItemCategory] = []
    var isLoading: Bool = false
    var error: Error? = nil

    private let context: ModelContext?

    init(context: ModelContext) {
        self.context = context
    }

    init() {
        self.context = nil
    }

    // MARK: - EntityStoreProtocol

    func fetchAll() async throws {
        guard let context else { return }
        isLoading = true
        error = nil
        do {
            let descriptor = FetchDescriptor<ItemCategory>(
                sortBy: [SortDescriptor(\ItemCategory.name, order: .forward)]
            )
            items = try context.fetch(descriptor)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func query(_ predicate: @escaping @Sendable (ItemCategory) -> Bool) async throws -> [ItemCategory] {
        guard let context else { return items.filter(predicate) }
        let descriptor = FetchDescriptor<ItemCategory>(
            sortBy: [SortDescriptor(\ItemCategory.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        return results.filter(predicate)
    }

    func insert(_ entity: ItemCategory) async throws {
        guard let context else {
            items.append(entity)
            return
        }
        context.insert(entity)
        items.append(entity)
    }

    func save(_ entity: ItemCategory) async throws {
        guard let context else { return }
        try context.save()
    }

    func delete(_ entity: ItemCategory) async throws {
        guard let context else {
            items.removeAll { $0.id == entity.id }
            return
        }
        context.delete(entity)
        items.removeAll { $0.id == entity.id }
        try context.save()
    }

    func refresh() async throws {
        try await fetchAll()
    }

    // MARK: - Factory Methods

    static func live() -> CategoryStore {
        CategoryStore(context: ModelContainer.mainContext)
    }

    static func preview() -> CategoryStore {
        let store = CategoryStore()
        store.items = [
            ItemCategory(name: "Electronics"),
            ItemCategory(name: "Personal"),
            ItemCategory(name: "Clothing")
        ]
        return store
    }

    static func test() -> CategoryStore {
        CategoryStore()
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Services/CategoryStore.swift"
git commit -m "feat: add CategoryStore with live, preview, and test implementations"
```

---

### Task 4: LocationStore

**Files:**
- Create: `All my stuff/Services/LocationStore.swift`

**Interfaces:**
- Consumes: `EntityStoreProtocol` from Task 1, `ItemLocation` model
- Produces: `LocationStore` class conforming to `EntityStoreProtocol<ItemLocation>` and `DependencyKey`

- [ ] **Step 1: Write LocationStore**

```swift
import Foundation
import SwiftData
import SwiftUI
import Dependencies

@Observable
final class LocationStore: EntityStoreProtocol, @unchecked Sendable {
    var items: [ItemLocation] = []
    var isLoading: Bool = false
    var error: Error? = nil

    private let context: ModelContext?

    init(context: ModelContext) {
        self.context = context
    }

    init() {
        self.context = nil
    }

    // MARK: - EntityStoreProtocol

    func fetchAll() async throws {
        guard let context else { return }
        isLoading = true
        error = nil
        do {
            let descriptor = FetchDescriptor<ItemLocation>(
                sortBy: [SortDescriptor(\ItemLocation.name, order: .forward)]
            )
            items = try context.fetch(descriptor)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func query(_ predicate: @escaping @Sendable (ItemLocation) -> Bool) async throws -> [ItemLocation] {
        guard let context else { return items.filter(predicate) }
        let descriptor = FetchDescriptor<ItemLocation>(
            sortBy: [SortDescriptor(\ItemLocation.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        return results.filter(predicate)
    }

    func insert(_ entity: ItemLocation) async throws {
        guard let context else {
            items.append(entity)
            return
        }
        context.insert(entity)
        items.append(entity)
    }

    func save(_ entity: ItemLocation) async throws {
        guard let context else { return }
        try context.save()
    }

    func delete(_ entity: ItemLocation) async throws {
        guard let context else {
            items.removeAll { $0.id == entity.id }
            return
        }
        context.delete(entity)
        items.removeAll { $0.id == entity.id }
        try context.save()
    }

    func refresh() async throws {
        try await fetchAll()
    }

    // MARK: - Factory Methods

    static func live() -> LocationStore {
        LocationStore(context: ModelContainer.mainContext)
    }

    static func preview() -> LocationStore {
        let store = LocationStore()
        store.items = [
            ItemLocation(name: "Desk"),
            ItemLocation(name: "Bag"),
            ItemLocation(name: "Shelf")
        ]
        return store
    }

    static func test() -> LocationStore {
        LocationStore()
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Services/LocationStore.swift"
git commit -m "feat: add LocationStore with live, preview, and test implementations"
```

---

### Task 5: DependencyKey Conformances + DependencyValues Registration

**Files:**
- Create: `All my stuff/Services/DependencyRegistration.swift`

**Interfaces:**
- Consumes: `ItemStore` from Task 2, `CategoryStore` from Task 3, `LocationStore` from Task 4
- Produces: `DependencyKey` conformances, `DependencyValues` extensions, `prepareDependencies()` helper

- [ ] **Step 1: Write DependencyRegistration**

```swift
import Dependencies

// MARK: - ItemStore Dependency

extension ItemStore: DependencyKey {
    static let liveValue: ItemStore = .live()
    static var previewValue: ItemStore { .preview() }
    static var testValue: ItemStore { .test() }
}

extension DependencyValues {
    var itemStore: ItemStore {
        get { self[ItemStore.self] }
        set { self[ItemStore.self] = newValue }
    }
}

// MARK: - CategoryStore Dependency

extension CategoryStore: DependencyKey {
    static let liveValue: CategoryStore = .live()
    static var previewValue: CategoryStore { .preview() }
    static var testValue: CategoryStore { .test() }
}

extension DependencyValues {
    var categoryStore: CategoryStore {
        get { self[CategoryStore.self] }
        set { self[CategoryStore.self] = newValue }
    }
}

// MARK: - LocationStore Dependency

extension LocationStore: DependencyKey {
    static let liveValue: LocationStore = .live()
    static var previewValue: LocationStore { .preview() }
    static var testValue: LocationStore { .test() }
}

extension DependencyValues {
    var locationStore: LocationStore {
        get { self[LocationStore.self] }
        set { self[LocationStore.self] = newValue }
    }
}

// MARK: - Prepare Dependencies

func prepareDependencies() {
    withDependencies {
        $0.itemStore = .live()
        $0.categoryStore = .live()
        $0.locationStore = .live()
    } operation: {
        // No-op — this establishes the live dependency values globally
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Services/DependencyRegistration.swift"
git commit -m "feat: register all stores as swift-dependencies with live/preview/test values"
```

---

### Task 6: Wire prepareDependencies in App Entry Point

**Files:**
- Modify: `All my stuff/All_my_stuffApp.swift`

**Interfaces:**
- Consumes: `prepareDependencies()` from Task 5

- [ ] **Step 1: Update All_my_stuffApp**

Replace the current file with:

```swift
import SwiftUI
import SwiftData

@main
struct All_my_stuffApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.tonisucic.All-my-stuff")
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    init() {
        prepareDependencies()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
```

The change: Add `init() { prepareDependencies() }`. Keep `.modelContainer(sharedModelContainer)` for now — live stores still need the container via `ModelContainer.mainContext`.

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/All_my_stuffApp.swift"
git commit -m "feat: call prepareDependencies at app launch"
```

---

### Task 7: Store Unit Tests (Preview Implementation)

**Files:**
- Create: `All my stuffTests/Services/ItemStoreTests.swift`

**Interfaces:**
- Consumes: `ItemStore` from Task 2, `CategoryStore` from Task 3

- [ ] **Step 1: Write store unit tests**

```swift
import Testing
@testable import All_my_stuff

@Suite("ItemStore Tests")
struct ItemStoreTests {

    @Test func previewStoreHasSampleData() async throws {
        let store = ItemStore.preview()
        #expect(store.items.count == 3)
        #expect(store.items[0].name == "Laptop")
        #expect(store.items[1].name == "Headphones")
        #expect(store.items[2].name == "Phone")
    }

    @Test func previewStoreInsertAddsItem() async throws {
        let store = ItemStore.preview()
        let newItem = Item(name: "Tablet")
        try await store.insert(newItem)
        #expect(store.items.count == 4)
    }

    @Test func previewStoreDeleteRemovesItem() async throws {
        let store = ItemStore.preview()
        let itemToDelete = store.items[0]
        try await store.delete(itemToDelete)
        #expect(store.items.count == 2)
        #expect(!store.items.contains { $0.name == "Laptop" })
    }

    @Test func previewStoreQueryFiltersCorrectly() async throws {
        let store = ItemStore.preview()
        let results = try await store.query { $0.name.contains("Laptop") }
        #expect(results.count == 1)
        #expect(results[0].name == "Laptop")
    }

    @Test func previewStoreQueryReturnsEmpty() async throws {
        let store = ItemStore.preview()
        let results = try await store.query { $0.name.contains("Nonexistent") }
        #expect(results.isEmpty)
    }

    @Test func testStoreIsEmpty() async throws {
        let store = ItemStore.test()
        #expect(store.items.isEmpty)
    }

    @Test func previewStoreGroupedByCategory() async throws {
        let store = ItemStore.preview()
        let grouped = store.grouped(by: \Item.categories)
        #expect(grouped.count > 0)
        #expect(grouped[0].group.name != "")
    }

    @Test func previewStoreGroupedByLocation() async throws {
        let store = ItemStore.preview()
        let grouped = store.groupedByLocation()
        #expect(grouped.count > 0)
    }
}

@Suite("CategoryStore Tests")
struct CategoryStoreTests {

    @Test func previewStoreHasSampleCategories() async throws {
        let store = CategoryStore.preview()
        #expect(store.items.count == 3)
    }

    @Test func testStoreIsEmpty() async throws {
        let store = CategoryStore.test()
        #expect(store.items.isEmpty)
    }
}

@Suite("LocationStore Tests")
struct LocationStoreTests {

    @Test func previewStoreHasSampleLocations() async throws {
        let store = LocationStore.preview()
        #expect(store.items.count == 3)
    }

    @Test func testStoreIsEmpty() async throws {
        let store = LocationStore.test()
        #expect(store.items.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests and verify**

Run: `xcode_RunSomeTests` for the new test files
Expected: All tests PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuffTests/Services/ItemStoreTests.swift"
git commit -m "test: add unit tests for ItemStore, CategoryStore, LocationStore preview implementations"
```

---

### Task 8: Migrate ItemListView

**Files:**
- Modify: `All my stuff/Views/ItemListView.swift`

**Interfaces:**
- Consumes: `ItemStore` via `@Dependency(\.itemStore)`, `CategoryStore` via `@Dependency(\.categoryStore)`, `LocationStore` via `@Dependency(\.locationStore)`

- [ ] **Step 1: Replace @Query and @Environment with @Dependency**

Replace the `ItemListView` struct body:

```swift
struct ItemListView: View {
    @Dependency(\.itemStore) private var itemStore
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all

    var filteredItems: [Item] {
        let items = itemStore.items
        if searchText.isEmpty {
            return items
        }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            if filterOption == .all {
                Section {
                    ForEach(filteredItems, id: \.persistentModelID) { item in
                        NavigationLink(value: item) {
                            ItemRowView(item: item)
                        }
                    }
                }
            } else if filterOption == .category {
                let grouped = itemStore.grouped(by: \Item.categories)
                if grouped.isEmpty {
                    Section {
                        Text("No items have categories yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(grouped.map { $0.group }, id: \.persistentModelID) { cat in
                        Section(cat.name) {
                            let categoryItems = grouped.first(where: { $0.group == cat })?.items ?? []
                            ForEach(categoryItems, id: \.persistentModelID) { item in
                                NavigationLink(value: item) {
                                    ItemRowView(item: item)
                                }
                            }
                        }
                    }
                }
            } else if filterOption == .location {
                let grouped = itemStore.groupedByLocation()
                if grouped.isEmpty {
                    Section {
                        Text("No items have locations yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(grouped.map { $0.group }, id: \.persistentModelID) { loc in
                        Section(loc.name) {
                            let locationItems = grouped.first(where: { $0.group == loc })?.items ?? []
                            ForEach(locationItems, id: \.persistentModelID) { item in
                                NavigationLink(value: item) {
                                    ItemRowView(item: item)
                                }
                            }
                        }
                    }
                }
            }

            if filteredItems.isEmpty && !searchText.isEmpty {
                Section {
                    Text("No items match your search.")
                        .foregroundStyle(.secondary)
                }
            }

            if itemStore.items.isEmpty {
                Section {
                    Text("No items yet. Tap + to create one.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("My Items")
        .searchable(text: $searchText, prompt: "Search items")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("Filter", selection: $filterOption) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
            }
        }
        .task {
            try await itemStore.fetchAll()
        }
    }
}
```

Remove `getUniqueCategories()` and `getUniqueLocations()` methods — grouping is now in the store.

Update the Preview:

```swift
#Preview {
    ContentView()
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Verify Preview works**

Run: `xcode_RenderPreview` on `ItemListView.swift`
Expected: Preview renders with sample data, no container errors

- [ ] **Step 4: Commit**

```bash
git add "All my stuff/Views/ItemListView.swift"
git commit -m "refactor: migrate ItemListView from @Query to @Dependency itemStore"
```

---

### Task 9: Migrate ContentView

**Files:**
- Modify: `All my stuff/Views/ContentView.swift`

**Interfaces:**
- Consumes: `ItemStore` via `@Dependency(\.itemStore)`

- [ ] **Step 1: Replace modelContext with itemStore**

Replace `createNewItem()` to use the store:

```swift
struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var selectedItem: Item?
    @State private var creatingItem: Item?
    @State private var editingItem: Item?
    @Dependency(\.itemStore) private var itemStore

    var body: some View {
        // ... body stays the same ...
    }

    private func createNewItem() {
        let newItem = Item(name: "New Item", datePurchased: Date())
        Task {
            try await itemStore.insert(newItem)
            try await itemStore.save(newItem)
        }
        creatingItem = newItem
    }
}
```

Update the Preview:

```swift
#Preview {
    ContentView()
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Verify Preview works**

Run: `xcode_RenderPreview` on `ContentView.swift`
Expected: Preview renders with sample data

- [ ] **Step 4: Commit**

```bash
git add "All my stuff/Views/ContentView.swift"
git commit -m "refactor: migrate ContentView from modelContext to @Dependency itemStore"
```

---

### Task 10: Migrate ItemFormSheet

**Files:**
- Modify: `All my stuff/Views/ItemFormSheet.swift`

**Interfaces:**
- Consumes: `ItemStore` via `@Dependency(\.itemStore)`, `CategoryStore` via `@Dependency(\.categoryStore)`, `LocationStore` via `@Dependency(\.locationStore)`

- [ ] **Step 1: Replace modelContext with itemStore**

Replace `@Environment(\.modelContext)` with `@Dependency(\.itemStore)`. Update the Cancel and Done buttons:

For Cancel (create mode deletion):
```swift
Button("Cancel") {
    if isCreateMode {
        Task {
            try await itemStore.delete(item)
        }
    }
    dismiss()
}
```

For Done (save):
```swift
Button {
    Task { @MainActor in
        isSaving = true
        do {
            try await itemStore.save(item)
            onDone()
            dismiss()
        } catch {
            // Save failed - stay on sheet to allow retry
        }
        isSaving = false
    }
} label: {
    if isSaving {
        ProgressView()
    } else {
        Text("Done")
    }
}
.disabled(isCreateMode && !isValid || isSaving)
```

Update the Preview:

```swift
#Preview {
    let store = ItemStore.preview()
    let item = store.items.first ?? Item(name: "Tablet")

    return ItemFormSheet(
        item: item,
        isCreateMode: false,
        onCancel: {},
        onDone: {}
    )
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Verify Preview works**

Run: `xcode_RenderPreview` on `ItemFormSheet.swift`
Expected: Preview renders form with sample data

- [ ] **Step 4: Commit**

```bash
git add "All my stuff/Views/ItemFormSheet.swift"
git commit -m "refactor: migrate ItemFormSheet from modelContext to @Dependency itemStore"
```

---

### Task 11: Migrate ItemProfileView

**Files:**
- Modify: `All my stuff/Views/ItemProfileView.swift`

**Interfaces:**
- Consumes: `ItemStore` via `@Dependency(\.itemStore)`

- [ ] **Step 1: Replace modelContext with itemStore**

Replace `@Environment(\.modelContext)` with `@Dependency(\.itemStore)`. Update `deleteItem()`:

```swift
extension ItemProfileView {
    private func deleteItem() {
        Task {
            try await itemStore.delete(item)
            onDelete()
        }
    }
}
```

Update the Preview:

```swift
#Preview {
    let store = ItemStore.preview()
    let item = store.items.first ?? Item(name: "Laptop")

    return NavigationStack {
        ItemProfileView(
            item: item,
            onEdit: {},
            onDelete: {}
        )
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Verify Preview works**

Run: `xcode_RenderPreview` on `ItemProfileView.swift`
Expected: Preview renders profile with sample data

- [ ] **Step 4: Commit**

```bash
git add "All my stuff/Views/ItemProfileView.swift"
git commit -m "refactor: migrate ItemProfileView from modelContext to @Dependency itemStore"
```

---

### Task 12: Migrate CategoryPickerView

**Files:**
- Modify: `All my stuff/Views/CategoryPickerView.swift`

**Interfaces:**
- Consumes: `CategoryStore` via `@Dependency(\.categoryStore)`

- [ ] **Step 1: Replace @Query and modelContext with categoryStore**

```swift
struct ItemCategoryPickerView: View {
    @Bindable var item: Item
    @Dependency(\.categoryStore) private var categoryStore

    var availableCategories: [ItemCategory] {
        categoryStore.items.filter { !(item.categories ?? []).contains($0) }
    }

    var categories: [ItemCategory] {
        get { item.categories ?? [] }
        set { item.categories = newValue }
    }

    var body: some View {
        Section("Categories") {
            if categories.isEmpty && categoryStore.items.isEmpty {
                Text("No categories yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(categories, id: \.persistentModelID) { cat in
                HStack {
                    Text(cat.name)
                    Spacer()
                    Button(role: .destructive) {
                        item.categories = (item.categories ?? []).filter { $0 != cat }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            ForEach(availableCategories, id: \.persistentModelID) { cat in
                Button("+ \(cat.name)") {
                    var current = item.categories ?? []
                    current.append(cat)
                    item.categories = current
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            TextField("New category", text: Binding(
                get: { "" },
                set: { newValue in
                    if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                        let newCat = ItemCategory(name: newValue.trimmingCharacters(in: .whitespaces))
                        Task {
                            try await categoryStore.insert(newCat)
                            try await categoryStore.save(newCat)
                        }
                        var current = item.categories ?? []
                        current.append(newCat)
                        item.categories = current
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
        .task {
            try await categoryStore.fetchAll()
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Views/CategoryPickerView.swift"
git commit -m "refactor: migrate CategoryPickerView from @Query to @Dependency categoryStore"
```

---

### Task 13: Migrate LocationPickerView

**Files:**
- Modify: `All my stuff/Views/LocationPickerView.swift`

**Interfaces:**
- Consumes: `LocationStore` via `@Dependency(\.locationStore)`

- [ ] **Step 1: Replace @Query and modelContext with locationStore**

```swift
struct ItemLocationPickerView: View {
    @Bindable var item: Item
    @Dependency(\.locationStore) private var locationStore

    var availableLocations: [ItemLocation] {
        locationStore.items.filter { !(item.locations ?? []).contains($0) }
    }

    var locations: [ItemLocation] {
        get { item.locations ?? [] }
        set { item.locations = newValue }
    }

    var body: some View {
        Section("Locations") {
            if locations.isEmpty && locationStore.items.isEmpty {
                Text("No locations yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(locations, id: \.persistentModelID) { loc in
                HStack {
                    Text(loc.name)
                    Spacer()
                    Button(role: .destructive) {
                        item.locations = (item.locations ?? []).filter { $0 != loc }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            ForEach(availableLocations, id: \.persistentModelID) { loc in
                Button("+ \(loc.name)") {
                    var current = item.locations ?? []
                    current.append(loc)
                    item.locations = current
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            TextField("New location", text: Binding(
                get: { "" },
                set: { newValue in
                    if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                        let newLoc = ItemLocation(name: newValue.trimmingCharacters(in: .whitespaces))
                        Task {
                            try await locationStore.insert(newLoc)
                            try await locationStore.save(newLoc)
                        }
                        var current = item.locations ?? []
                        current.append(newLoc)
                        item.locations = current
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
        .task {
            try await locationStore.fetchAll()
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Views/LocationPickerView.swift"
git commit -m "refactor: migrate LocationPickerView from @Query to @Dependency locationStore"
```

---

### Task 14: Remove import SwiftData from All View Files

**Files:**
- Modify: `All my stuff/Views/ContentView.swift`
- Modify: `All my stuff/Views/ItemListView.swift`
- Modify: `All my stuff/Views/ItemFormSheet.swift`
- Modify: `All my stuff/Views/ItemProfileView.swift`
- Modify: `All my stuff/Views/CategoryPickerView.swift`
- Modify: `All my stuff/Views/LocationPickerView.swift`

- [ ] **Step 1: Remove `import SwiftData` from each view file**

In each of the 6 view files, remove the line `import SwiftData`. The views no longer reference any SwiftData types directly.

- [ ] **Step 2: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS — this is the critical verification that views are fully decoupled from SwiftData

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Views/*.swift"
git commit -m "refactor: remove import SwiftData from all view files"
```

---

### Task 15: Remove PreviewHelper and Update All Previews

**Files:**
- Delete: `All my stuff/Services/PreviewHelper.swift`

- [ ] **Step 1: Verify all previews no longer reference PreviewHelper**

Check that `makeContentViewPreview()`, `makeProfilePreview()`, and `makePreviewContainer()` are no longer called in any `#Preview` block. All previews should now be self-contained using `previewValue`.

- [ ] **Step 2: Delete PreviewHelper.swift**

Remove `All my stuff/Services/PreviewHelper.swift` from the project.

- [ ] **Step 3: Build and verify**

Run: `xcode_BuildProject`
Expected: PASS

- [ ] **Step 4: Verify all previews work**

Run: `xcode_RenderPreview` on each view file:
- `ContentView.swift`
- `ItemListView.swift`
- `ItemFormSheet.swift`
- `ItemProfileView.swift`

Expected: All previews render with sample data, zero container setup

- [ ] **Step 5: Commit**

```bash
git rm "All my stuff/Services/PreviewHelper.swift"
git commit -m "refactor: remove PreviewHelper — previews now use swift-dependencies previewValue"
```

---

### Task 16: Run Full Test Suite and Final Build

**Files:**
- No file changes

- [ ] **Step 1: Run all tests**

Run: `xcode_RunAllTests`
Expected: All tests PASS (existing integration tests + new store unit tests)

- [ ] **Step 2: Full build**

Run: `xcode_BuildProject`
Expected: PASS with no errors

- [ ] **Step 3: Verify no SwiftData imports in Views**

Search for `import SwiftData` in `All my stuff/Views/` — should find zero matches.

- [ ] **Step 4: Commit final state**

```bash
git add -A
git commit -m "feat: complete database abstraction — views use @Observable stores via swift-dependencies"
```

---

### Task 17: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md` (outside Xcode project, use generic tools)

- [ ] **Step 1: Update conventions section**

The following rules are already added (from the design session). Verify they exist and are accurate:
- Rule 11: No SwiftData in Views
- Rule 12: swift-dependencies for injection
- Rule 13: Previews must not require container setup

If any need refinement based on the actual implementation, update them.

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs: verify AGENTS.md conventions match implemented store pattern"
```
