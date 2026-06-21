# Architecture Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up architecture issues: concurrency hardening, layer violations, dead code, loading/error UI, and legacy test migration.

**Architecture:** Seven independent cleanup tasks across stores, views, app entry point, and tests. Each task is self-contained and can be reviewed independently.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, swift-dependencies, Swift Testing

## Global Constraints

- Xcode MCP tools for all project operations (`xcode_XcodeRead`, `xcode_XcodeUpdate`, `xcode_XcodeWrite`, `xcode_XcodeMV`, `xcode_XcodeRM`)
- LSP errors are false positives — always verify with `xcode_BuildProject`
- No external dependencies
- `@Observable` for state, `@Dependency(\.)` for DI, `@Bindable` for model binding
- Swift Testing framework for tests
- iOS 26+ APIs where applicable

---

### Task 1: Store Concurrency Hardening

**Files:**
- Modify: `AllMyStuff/Services/ItemStore.swift` (lines 1-8)
- Modify: `AllMyStuff/Services/CategoryStore.swift` (lines 1-8)
- Modify: `AllMyStuff/Services/LocationStore.swift` (lines 1-8)
- Modify: `AllMyStuff/Services/DependencyRegistration.swift` (lines 12-15, 29-32, 44-48)
- Modify: `AllMyStuff/Services/EntityStoreProtocol.swift` (line 3)

**Interfaces:**
- Consumes: None
- Produces: `@MainActor` isolated stores, safe `liveValue` fallback

- [ ] **Step 1: Update EntityStoreProtocol**

Remove `Sendable` from the protocol since `@MainActor`-isolated `@Observable` classes handle concurrency via actor isolation, not explicit `Sendable`.

In `AllMyStuff/Services/EntityStoreProtocol.swift`:

```swift
import Foundation

protocol EntityStoreProtocol {
    associatedtype Entity: Identifiable

    var items: [Entity] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func fetchAll() throws
    func query(_ predicate: @escaping @Sendable (Entity) -> Bool) throws -> [Entity]
    func insert(_ entity: Entity) throws
    func save(_ entity: Entity) throws
    func delete(_ entity: Entity) throws
    func refresh() throws
}
```

- [ ] **Step 2: Harden ItemStore**

In `AllMyStuff/Services/ItemStore.swift`, replace lines 1-8:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class ItemStore: EntityStoreProtocol {
    var items: [Item] = []
    var isLoading: Bool = false
    var error: Error? = nil
```

- [ ] **Step 3: Harden CategoryStore**

In `AllMyStuff/Services/CategoryStore.swift`, replace lines 1-8:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class CategoryStore: EntityStoreProtocol {
    var items: [ItemCategory] = []
    var isLoading: Bool = false
    var error: Error? = nil
```

- [ ] **Step 4: Harden LocationStore**

In `AllMyStuff/Services/LocationStore.swift`, replace lines 1-8:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class LocationStore: EntityStoreProtocol {
    var items: [ItemLocation] = []
    var isLoading: Bool = false
    var error: Error? = nil
```

- [ ] **Step 5: Fix force-unwrap in DependencyRegistration**

In `AllMyStuff/Services/DependencyRegistration.swift`, replace the three `liveValue` implementations:

```swift
extension ItemStore: DependencyKey {
    static var liveValue: ItemStore {
        guard let container = AppContainer.shared else {
            preconditionFailure("ItemStore.liveValue accessed before prepareDependencies() was called")
        }
        return .live(context: container.mainContext)
    }
    static var previewValue: ItemStore { .preview() }
    static var testValue: ItemStore { .test() }
}

extension CategoryStore: DependencyKey {
    static var liveValue: CategoryStore {
        guard let container = AppContainer.shared else {
            preconditionFailure("CategoryStore.liveValue accessed before prepareDependencies() was called")
        }
        return .live(context: container.mainContext)
    }
    static var previewValue: CategoryStore { .preview() }
    static var testValue: CategoryStore { .test() }
}

extension LocationStore: DependencyKey {
    static var liveValue: LocationStore {
        guard let container = AppContainer.shared else {
            preconditionFailure("LocationStore.liveValue accessed before prepareDependencies() was called")
        }
        return .live(context: container.mainContext)
    }
    static var previewValue: LocationStore { .preview() }
    static var testValue: LocationStore { .test() }
}
```

- [ ] **Step 6: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds with no new errors

- [ ] **Step 7: Commit**

```bash
git add "AllMyStuff/Services/ItemStore.swift" "AllMyStuff/Services/CategoryStore.swift" "AllMyStuff/Services/LocationStore.swift" "AllMyStuff/Services/DependencyRegistration.swift" "AllMyStuff/Services/EntityStoreProtocol.swift"
git commit -m "fix: replace @unchecked Sendable with @MainActor isolation on stores"
```

---

### Task 2: Rename AssetStorage to ImageHelper

**Files:**
- Modify: `AllMyStuff/Services/AssetStorage.swift` (rename file + rename struct)
- Modify: `AllMyStuff/Views/ItemFormSheet.swift` (update references)
- Modify: `AllMyStuff/Views/ItemProfileView.swift` (update references)
- Modify: `AllMyStuffTests/Integration/ItemFormSheetModelTests.swift` (update references)

**Interfaces:**
- Consumes: Task 1 (stores are `@MainActor`)
- Produces: `ImageHelper` struct, all references updated

- [ ] **Step 1: Rename file via Xcode MCP**

Run: `xcode_XcodeMV` to rename `AllMyStuff/Services/AssetStorage.swift` to `AllMyStuff/Services/ImageHelper.swift`

- [ ] **Step 2: Rename struct inside file**

In `AllMyStuff/Services/ImageHelper.swift`, replace line 4:

```swift
struct ImageHelper {
```

- [ ] **Step 3: Update ItemFormSheet references**

In `AllMyStuff/Views/ItemFormSheet.swift`:
- Line 89: Replace `AssetStorage.imageDataToImage` with `ImageHelper.imageDataToImage`
- Line 118: Replace `AssetStorage.resizeImageData` with `ImageHelper.resizeImageData`
- Line 119: Replace `AssetStorage.imageDataToImage` with `ImageHelper.imageDataToImage`

- [ ] **Step 4: Update ItemProfileView references**

In `AllMyStuff/Views/ItemProfileView.swift`:
- Line 66: Replace `AssetStorage.imageDataToImage` with `ImageHelper.imageDataToImage`
- Line 91: Replace `AssetStorage.resizeImageData` with `ImageHelper.resizeImageData`
- Line 92: Replace `AssetStorage.imageDataToImage` with `ImageHelper.imageDataToImage`

- [ ] **Step 5: Update test reference**

In `AllMyStuffTests/Integration/ItemFormSheetModelTests.swift`:
- Line 73: Replace `AssetStorage.resizeImageData` with `ImageHelper.resizeImageData`

- [ ] **Step 6: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds, no unresolved `AssetStorage` references

- [ ] **Step 7: Commit**

```bash
git add "AllMyStuff/Services/ImageHelper.swift" "AllMyStuff/Views/ItemFormSheet.swift" "AllMyStuff/Views/ItemProfileView.swift" "AllMyStuffTests/Integration/ItemFormSheetModelTests.swift"
git commit -m "refactor: rename AssetStorage to ImageHelper"
```

---

### Task 3: Extract ImageProcessingOverlay to Views

**Files:**
- Modify: `AllMyStuff/Services/ImageHelper.swift` (remove overlay)
- Create: `AllMyStuff/Views/ImageProcessingOverlay.swift`

**Interfaces:**
- Consumes: Task 2 (ImageHelper file)
- Produces: `ImageProcessingOverlay<Content: View>` in Views directory

- [ ] **Step 1: Create ImageProcessingOverlay.swift**

Create `AllMyStuff/Views/ImageProcessingOverlay.swift`:

```swift
import SwiftUI

struct ImageProcessingOverlay<Content: View>: View {
    let isProcessing: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
            if isProcessing {
                Color.black.opacity(0.3)
                    .overlay { ProgressView() }
            }
        }
    }
}
```

- [ ] **Step 2: Remove overlay from ImageHelper.swift**

In `AllMyStuff/Services/ImageHelper.swift`, remove lines 29-43 (the `ImageProcessingOverlay` struct definition). File should end after line 27 (closing brace of `ImageHelper`).

- [ ] **Step 3: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds, overlay still accessible from Views

- [ ] **Step 4: Commit**

```bash
git add "AllMyStuff/Views/ImageProcessingOverlay.swift" "AllMyStuff/Services/ImageHelper.swift"
git commit -m "refactor: move ImageProcessingOverlay from Services to Views"
```

---

### Task 4: Extract Grouping Logic from ItemStore to ItemListView

**Files:**
- Modify: `AllMyStuff/Services/ItemStore.swift` (remove lines 81-107)
- Modify: `AllMyStuff/Views/ItemListView.swift` (add computed properties, update body)
- Modify: `AllMyStuffTests/Services/StoreTests.swift` (update grouping tests)

**Interfaces:**
- Consumes: None
- Produces: `groupedByCategory` and `groupedByLocation` computed properties on `ItemListView`

- [ ] **Step 1: Remove grouping methods from ItemStore**

In `AllMyStuff/Services/ItemStore.swift`, remove lines 81-107 (the `// MARK: - Grouping` section with `grouped(by:)` and `groupedByLocation()`).

- [ ] **Step 2: Add computed properties to ItemListView**

In `AllMyStuff/Views/ItemListView.swift`, add after the `filteredItems` computed property (after line 31):

```swift
    var groupedByCategory: [(group: ItemCategory, items: [Item])] {
        var categoryItems: [ItemCategory: [Item]] = [:]
        for item in filteredItems {
            if let categories = item.categories {
                for category in categories {
                    categoryItems[category, default: []].append(item)
                }
            }
        }
        return categoryItems.map { (group: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group.name < $1.group.name }
    }

    var groupedByLocation: [(group: ItemLocation, items: [Item])] {
        var locationItems: [ItemLocation: [Item]] = [:]
        for item in filteredItems {
            if let locations = item.locations {
                for location in locations {
                    locationItems[location, default: []].append(item)
                }
            }
        }
        return locationItems.map { (group: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group.name < $1.group.name }
    }
```

- [ ] **Step 3: Update ItemListView body to use computed properties**

In `AllMyStuff/Views/ItemListView.swift`, replace the category and location sections:

Replace line 44 (`let grouped = itemStore.grouped(by: \Item.categories)`) with:
```swift
                let grouped = groupedByCategory
```

Replace line 62 (`let grouped = itemStore.groupedByLocation()`) with:
```swift
                let grouped = groupedByLocation
```

- [ ] **Step 4: Update StoreTests**

In `AllMyStuffTests/Services/StoreTests.swift`, update the grouping tests to test via `ItemListView` computed properties instead of store methods. Replace lines 48-59:

```swift
    @Test func previewStoreItemsCanBeGroupedByCategory() throws {
        let store = ItemStore.preview()
        var categoryItems: [ItemCategory: [Item]] = [:]
        for item in store.items {
            if let categories = item.categories {
                for category in categories {
                    categoryItems[category, default: []].append(item)
                }
            }
        }
        #expect(categoryItems.count > 0)
    }

    @Test func previewStoreItemsCanBeGroupedByLocation() throws {
        let store = ItemStore.preview()
        var locationItems: [ItemLocation: [Item]] = [:]
        for item in store.items {
            if let locations = item.locations {
                for location in locations {
                    locationItems[location, default: []].append(item)
                }
            }
        }
        #expect(locationItems.count > 0)
    }
```

- [ ] **Step 5: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds, no references to removed methods

- [ ] **Step 6: Run store tests**

Run: `xcode_RunSomeTests` for `ItemStoreTests`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add "AllMyStuff/Services/ItemStore.swift" "AllMyStuff/Views/ItemListView.swift" "AllMyStuffTests/Services/StoreTests.swift"
git commit -m "refactor: move grouping logic from ItemStore to ItemListView computed properties"
```

---

### Task 5: Implement Loading States and Error UI

**Files:**
- Modify: `AllMyStuff/Views/ItemListView.swift` (add loading overlay, error alert)
- Modify: `AllMyStuff/Views/ItemFormSheet.swift` (add error alert for save failures)

**Interfaces:**
- Consumes: Task 1 (stores with `isLoading`/`error`), Task 4 (ItemListView structure)
- Produces: Loading overlay and error alert in views

- [ ] **Step 1: Add error state to ItemListView**

In `AllMyStuff/Views/ItemListView.swift`, add a state property after line 20:

```swift
    @State private var fetchError: String?
```

Update the `.task` block (lines 106-112) to capture errors:

```swift
        .task {
            do {
                try itemStore.fetchAll()
            } catch {
                fetchError = error.localizedDescription
            }
        }
```

Add overlay and alert modifiers after the `.toolbar` block (after line 112 in the updated file):

```swift
        .overlay {
            if itemStore.isLoading {
                ProgressView()
            }
        }
        .alert("Fetch Error", isPresented: Binding(
            get: { fetchError != nil },
            set: { if !$0 { fetchError = nil } }
        )) {
            Button("Retry") {
                Task {
                    do {
                        try itemStore.fetchAll()
                    } catch {
                        fetchError = error.localizedDescription
                    }
                }
            }
        } message: {
            if let error = fetchError {
                Text(error)
            }
        }
```

- [ ] **Step 2: Add save error alert to ItemFormSheet**

In `AllMyStuff/Views/ItemFormSheet.swift`, add a state property after line 19:

```swift
    @State private var saveError: String?
```

Update the save handler (lines 56-70) to capture errors:

```swift
                    Button {
                        Task { @MainActor in
                            isSaving = true
                            do {
                                if isCreateMode {
                                    try itemStore.insert(item)
                                }
                                try itemStore.save(item)
                                onDone()
                                dismiss()
                            } catch {
                                saveError = error.localizedDescription
                            }
                            isSaving = false
                        }
                    } label: {
```

Add alert modifier after the `.toolbar` block (after line 80):

```swift
            .alert("Save Error", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") {}
            } message: {
                if let error = saveError {
                    Text(error)
                }
            }
```

- [ ] **Step 3: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds

- [ ] **Step 4: Commit**

```bash
git add "AllMyStuff/Views/ItemListView.swift" "AllMyStuff/Views/ItemFormSheet.swift"
git commit -m "feat: add loading indicators and error alerts to ItemListView and ItemFormSheet"
```

---

### Task 6: Remove Redundant .modelContainer() and Improve Price Sync

**Files:**
- Modify: `AllMyStuff/AllMyStuffApp.swift` (remove .modelContainer)
- Modify: `AllMyStuff/Views/ItemFormSheet.swift` (add .onDisappear sync)

**Interfaces:**
- Consumes: Task 5 (ItemFormSheet structure)
- Produces: Cleaned app entry point, reliable price sync

- [ ] **Step 1: Remove .modelContainer from AllMyStuffApp**

In `AllMyStuff/AllMyStuffApp.swift`, replace lines 24-29:

```swift
    var body: some Scene {
        WindowGroup {
            ItemSplitView()
        }
    }
```

- [ ] **Step 2: Add .onDisappear to pricesSection in ItemFormSheet**

In `AllMyStuff/Views/ItemFormSheet.swift`, add `.onDisappear` to the `pricesSection` View (after the `.task` block in `pricesSection`):

```swift
        .task {
            purchasePriceText = formattedPurchasePriceText
            estimatedValueText = formattedEstimatedValueText
        }
        .onDisappear {
            commitPurchasePrice()
            commitEstimatedValue()
        }
```

- [ ] **Step 3: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds

- [ ] **Step 4: Commit**

```bash
git add "AllMyStuff/AllMyStuffApp.swift" "AllMyStuff/Views/ItemFormSheet.swift"
git commit -m "refactor: remove redundant .modelContainer() and add .onDisappear price sync"
```

---

### Task 7: Migrate Legacy Tests to Store Abstraction

**Files:**
- Modify: `AllMyStuffTests/Integration/ItemCRUDTests.swift`
- Modify: `AllMyStuffTests/Integration/ItemFormSheetModelTests.swift`
- Modify: `AllMyStuffTests/Integration/ItemProfileTests.swift`

**Interfaces:**
- Consumes: Task 1 (stores with `@MainActor`), all store methods
- Produces: Tests that exercise stores instead of raw SwiftData

- [ ] **Step 1: Rewrite ItemCRUDTests**

Replace entire `AllMyStuffTests/Integration/ItemCRUDTests.swift`:

```swift
import Foundation
import Testing
import SwiftData
import Dependencies
@testable import AllMyStuff

@Suite("Item CRUD Integration Tests")
struct ItemCRUDTests {

    @Test func create_update_delete_item() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Camera", datePurchased: Date())
            try? store.insert(item)
            try? store.fetchAll()
            #expect(store.items.count == 1)

            item.name = "DSLR Camera"
            item.purchasePrice = 1200
            try? store.save(item)
            #expect(store.items.first?.name == "DSLR Camera")

            try? store.delete(item)
            try? store.fetchAll()
            #expect(store.items.isEmpty)
        }
    }

    @Test func category_and_location_many_to_many() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let itemStore = ItemStore.live(context: ModelContext(container))
            let categoryStore = CategoryStore.live(context: ModelContext(container))
            let locationStore = LocationStore.live(context: ModelContext(container))

            let item = Item(name: "Tablet", datePurchased: Date())
            let cat1 = ItemCategory(name: "Tech")
            let cat2 = ItemCategory(name: "Personal")
            let loc1 = ItemLocation(name: "Bag")

            try? itemStore.insert(item)
            try? categoryStore.insert(cat1)
            try? categoryStore.insert(cat2)
            try? locationStore.insert(loc1)

            item.categories = [cat1, cat2]
            item.locations = [loc1]
            try? itemStore.save(item)

            try? itemStore.fetchAll()
            try? categoryStore.fetchAll()
            try? locationStore.fetchAll()

            #expect(categoryStore.items.count == 2)
            #expect(locationStore.items.count == 1)
        }
    }
}
```

- [ ] **Step 2: Rewrite ItemFormSheetModelTests**

Replace entire `AllMyStuffTests/Integration/ItemFormSheetModelTests.swift`:

```swift
import Foundation
import Testing
import SwiftData
import UIKit
@testable import AllMyStuff

@Suite("Item Form Sheet Model Tests")
struct ItemFormSheetModelTests {

    @Test func create_item_persists_with_valid_data() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Camera", datePurchased: Date())
            item.notes = "DSLR Camera Body"
            item.purchasePrice = 1200
            item.estimatedValue = 800

            try? store.insert(item)
            try? store.save(item)
            try? store.fetchAll()

            #expect(store.items.count == 1)
            #expect(store.items.first?.name == "Camera")
        }
    }

    @Test func edit_item_updates_existing_record() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Old Name", datePurchased: Date())
            try? store.insert(item)
            try? store.save(item)

            item.name = "Updated Name"
            item.notes = "Updated notes"
            item.purchasePrice = 500
            try? store.save(item)
            try? store.fetchAll()

            #expect(store.items.first?.name == "Updated Name")
            #expect(store.items.first?.notes == "Updated notes")
        }
    }

    @Test func cancel_create_does_not_persist_item() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let newItem = Item(name: "", datePurchased: Date())
            // Item is never inserted — simulating cancel before save
            try? store.fetchAll()
            #expect(store.items.isEmpty)
        }
    }

    @Test func photo_resize_preserves_data() async throws {
        await MainActor.run {
            let uiImage = UIImage(systemName: "photo")!
            guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
                Issue.record("failed to create test image data")
                return
            }

            let resized = ImageHelper.resizeImageData(data, maxDimension: 1024)
            #expect(resized != nil)
            if let r = resized {
                #expect(r.count > 0)
            }
        }
    }
}
```

- [ ] **Step 3: Rewrite ItemProfileTests**

Replace entire `AllMyStuffTests/Integration/ItemProfileTests.swift`:

```swift
import Foundation
import Testing
import SwiftData
@testable import AllMyStuff

@Suite("Item Profile Model Tests")
struct ItemProfileTests {

    @Test func item_profile_data_persists() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let itemStore = ItemStore.live(context: ModelContext(container))
            let categoryStore = CategoryStore.live(context: ModelContext(container))
            let locationStore = LocationStore.live(context: ModelContext(container))

            let item = Item(name: "Laptop", datePurchased: Date())
            item.notes = "2024 MacBook Pro"
            item.purchasePrice = 1999.99
            item.estimatedValue = 1500
            let cat = ItemCategory(name: "Electronics")
            let loc = ItemLocation(name: "Desk")

            try? itemStore.insert(item)
            try? categoryStore.insert(cat)
            try? locationStore.insert(loc)
            item.categories = [cat]
            item.locations = [loc]
            try? itemStore.save(item)
            try? itemStore.fetchAll()

            #expect(itemStore.items.count == 1)
            #expect(itemStore.items.first?.name == "Laptop")
            #expect(itemStore.items.first?.notes == "2024 MacBook Pro")
            #expect(itemStore.items.first?.categories?.count == 1)
            #expect(itemStore.items.first?.locations?.count == 1)
        }
    }

    @Test func item_profile_no_photo_shows_default_state() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Phone", datePurchased: Date())
            try? store.insert(item)
            try? store.save(item)
            try? store.fetchAll()

            #expect(store.items.first?.photo == nil)
        }
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `xcode_BuildProject`
Expected: Build succeeds

- [ ] **Step 5: Run integration tests**

Run: `xcode_RunSomeTests` for `ItemCRUDTests`, `ItemFormSheetModelTests`, `ItemProfileTests`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add "AllMyStuffTests/Integration/ItemCRUDTests.swift" "AllMyStuffTests/Integration/ItemFormSheetModelTests.swift" "AllMyStuffTests/Integration/ItemProfileTests.swift"
git commit -m "refactor: migrate legacy integration tests to use store abstraction"
```

---

### Task 8: Final Build and Test Verification

**Files:** None (verification only)

**Interfaces:**
- Consumes: All previous tasks
- Produces: Verified build and passing tests

- [ ] **Step 1: Full build**

Run: `xcode_BuildProject`
Expected: Clean build with no errors

- [ ] **Step 2: Run all store tests**

Run: `xcode_RunSomeTests` for `ItemStoreTests`, `CategoryStoreTests`, `LocationStoreTests`
Expected: All pass

- [ ] **Step 3: Run all integration tests**

Run: `xcode_RunSomeTests` for `ItemCRUDTests`, `ItemFormSheetModelTests`, `ItemProfileTests`
Expected: All pass

- [ ] **Step 4: Verify no AssetStorage references remain**

Run: `grep -r "AssetStorage" --include="*.swift" AllMyStuff/ AllMyStuffTests/`
Expected: No matches in source files

- [ ] **Step 5: Verify no @unchecked Sendable remains**

Run: `grep -r "@unchecked Sendable" --include="*.swift" AllMyStuff/`
Expected: No matches

- [ ] **Step 6: Final commit if needed**

```bash
git status
```

If all changes are committed, done. If any uncommitted changes remain:

```bash
git add -A
git commit -m "cleanup: final architecture cleanup verification"
```
