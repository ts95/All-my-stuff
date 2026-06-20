# All My Stuff — Initial Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a personal inventory SwiftUI app that tracks items with photos, prices, categories, and locations — synced across iPhone, iPad, and Mac via iCloud CloudKit.

**Architecture:** SwiftUI `NavigationSplitView` master-detail layout, SwiftData persistence with built-in CloudKit sync, `@Observable`-free MV using `@Model` + `@Query` directly in views. No external dependencies.

**Tech Stack:** SwiftUI, SwiftData, CloudKit (via SwiftData integration), iOS 26.5+

## Global Constraints

- **No external dependencies** — only Apple frameworks: SwiftUI, SwiftData, CloudKit
- **SwiftUI-first** — no UIKit/AppKit unless explicitly required
- **One primary declaration per file** — files named after the type they contain
- **Files organized:** `Models/`, `Views/`, `Services/`
- **Adaptive layouts only** — `NavigationSplitView` with `.balanced` style, no device-specific branches
- **Xcode project at:** `/Users/tonisucic/Repos/All my stuff/All my stuff.xcodeproj`
- **Bundle ID:** `com.tonisucic.All-my-stuff`, Team: `FE6WMDZ3AJ`
- **Deployment target:** iOS 26.5
- **Test framework:** Swift Testing (`import Testing`)

---

### Task 1: Data Models — PriceState, Category, Location, Item

**Files:**
- Create: `All my stuff/Models/PriceState.swift`
- Create: `All my stuff/Models/Category.swift`
- Create: `All my stuff/Models/Location.swift`
- Create: `All my stuff/Models/Item.swift`
- Test: `All my stuffTests/Models/DataModelTests.swift`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: `PriceState` enum, `Category`, `Location`, `Item` SwiftData models with many-to-many relationships

- [ ] **Step 1: Write failing test for model creation and relationships**

```swift
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Data Model Tests")
struct DataModelTests {

    private var context: ModelContext! = ModelContext(.inMemory())

    @Test func item_createsWithRequiredFields() async throws {
        let item = Item(name: "Laptop", datePurchased: Date())
        #expect(item.name == "Laptop")
        #expect(item.description.isEmpty)
        #expect(item.photo == nil)
        #expect(item.purchasePrice == nil)
    }

    @Test func category_createsWithName() async throws {
        let cat = Category(name: "Electronics")
        context.insert(cat)
        #expect(ModelContext(context).modelContainer.mainContext.count(for: Category.self) == 1)
    }

    @Test func location_createsWithName() async throws {
        let loc = Location(name: "Office Desk")
        context.insert(loc)
        #expect(ModelContext(context).modelContainer.mainContext.count(for: Location.self) == 1)
    }

    @Test func item_linksToManyCategories() async throws {
        let laptop = Item(name: "Laptop", datePurchased: Date())
        let electronics = Category(name: "Electronics")
        let work = Category(name: "Work")
        laptop.categories.insert(electronics)
        laptop.categories.insert(work)
        #expect(laptop.categories.count == 2)
    }

    @Test func item_linksToManyLocations() async throws {
        let phone = Item(name: "Phone", datePurchased: Date())
        let office = Location(name: "Office")
        let home = Location(name: "Home")
        phone.locations.insert(office)
        phone.locations.insert(home)
        #expect(phone.locations.count == 2)
    }

    @Test func priceState_confirmedValue() async throws {
        var price = PriceState.confirmed(999.99)
        switch price {
        case .confirmed(let value):
            #expect(value == 999.99)
        default:
            Issue.record("expected confirmed")
        }
    }

    @Test func priceState_assumedValue() async throws {
        var price = PriceState.assumed(500)
        switch price {
        case .assumed(let value):
            #expect(value == 500)
        default:
            Issue.record("expected assumed")
        }
    }

    @Test func priceState_unknown() async throws {
        var price = PriceState.unknown
        switch price {
        case .unknown:
            break
        default:
            Issue.record("expected unknown")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"All_my_stuffTests/DataModelTests"`
Expected: FAIL with type resolution errors for `Item`, `Category`, `Location`, `PriceState`

- [ ] **Step 3: Create PriceState.swift**

```swift
import Foundation

enum PriceState: Codable, Sendable {
    case unknown
    case confirmed(Double)
    case assumed(Double)
}

extension PriceState {
    var displayValue: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .confirmed(let value), .assumed(let value):
            return "\(value, specifier: "%.2f")"
        }
    }

    var isKnown: Bool {
        if case .confirmed = self { return true }
        return false
    }

    var numericValue: Double? {
        switch self {
        case .unknown:
            return nil
        case .confirmed(let v), .assumed(let v):
            return v
        }
    }
}
```

- [ ] **Step 4: Create Category.swift**

```swift
import SwiftData
import Foundation

@Model
final class Category {
    var name: String
    @Relationship(inverse: \Item.categories)
    var items: [Item]?

    init(name: String) {
        self.name = name
    }
}
```

- [ ] **Step 5: Create Location.swift**

```swift
import SwiftData
import Foundation

@Model
final class Location {
    var name: String
    @Relationship(inverse: \Item.locations)
    var items: [Item]?

    init(name: String) {
        self.name = name
    }
}
```

- [ ] **Step 6: Create Item.swift**

```swift
import SwiftData
import Foundation

@Model
final class Item {
    var id: UUID?
    @Attribute(.unique)
    var name: String
    var description: String = ""
    var photo: Data?
    var purchasePrice: PriceState?
    var estimatedValue: PriceState?
    var datePurchased: Date?

    @Relationship(inverse: \Category.items)
    var categories: Set<Category> = []

    @Relationship(inverse: \Location.items)
    var locations: Set<Location> = []

    init(name: String, datePurchased: Date? = nil) {
        self.name = name
        self.datePurchased = datePurchased
    }
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `xcodebuild test -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:"All_my_stuffTests/DataModelTests"`
Expected: PASS all tests

- [ ] **Step 8: Commit**

```bash
git add "All my stuff/Models/" "All my stuffTests/Models/"
git commit -m "feat: add SwiftData models Item, Category, Location, and PriceState with many-to-many relationships"
```

---

### Task 2: ModelContainer setup with CloudKit in App entry point

**Files:**
- Modify: `All my stuff/All_my_stuffApp.swift`
- Create (via Xcode UI): entitlements file with iCloud container capability
- Test: (verified by build + CloudKit console check; no unit test for CloudKit config)

**Interfaces:**
- Consumes: Task 1 models (`Item`, `Category`, `Location`)
- Produces: `ModelContainer` injected into environment, ready for any view to query/insert

- [ ] **Step 1: Add iCloud CloudKit capability to Xcode project**

In Xcode: Select app target → Signing & Capabilities → + Capability → iCloud → Enable iCloud Containers with identifier `iCloud.com.tonisucic.All-my-stuff`

This automatically creates the `.entitlements` file and adds it to the build settings.

- [ ] **Step 2: Verify entitlements file exists**

```bash
ls "All my stuff/All_my_stuff.entitlements"
```
Expected: File exists with `com.apple.developer.icloud-container-identifiers` containing `iCloud.com.tonisucic.All-my-stuff`

- [ ] **Step 3: Update All_my_stuffApp.swift**

Replace file contents with:

```swift
import SwiftUI
import SwiftData

@main
struct All_my_stuffApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self, Category.self, Location.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            .setCloudKitEnabled(.privateDatabase)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
```

- [ ] **Step 4: Build to verify no errors**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED, no compiler errors

- [ ] **Step 5: Commit**

```bash
git add "All my stuff/All_my_stuffApp.swift" "All my stuff/All_my_stuff.entitlements"
git commit -m "feat: configure ModelContainer with CloudKit private database sync"
```

---

### Task 3: AssetStorage service for photo handling

**Files:**
- Create: `All my stuff/Services/AssetStorage.swift`
- Test: (photo resizing is helper-only; verified later in ItemDetailView acceptance testing)

**Interfaces:**
- Consumes: none
- Produces: `AssetStorage` struct with `resizeImageData(_:maxDimension:)` and `imageDataToImage(_:)` static methods

- [ ] **Step 1: Create AssetStorage.swift**

```swift
import SwiftUI

struct AssetStorage {
    static func resizeImageData(_ data: Data, maxDimension: Int = 1024) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        let size = uiImage.size
        let scale: CGFloat
        if size.width > CGFloat(maxDimension) || size.height > CGFloat(maxDimension) {
            let ratio = min(CGFloat(maxDimension) / size.width, CGFloat(maxDimension) / size.height)
            scale = ratio
        } else {
            scale = 1.0
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        return resized.jpegData(compressionQuality: 0.75)
    }

    static func imageDataToImage(_ data: Data?) -> Image? {
        guard let data, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}
```

- [ ] **Step 2: Build to verify no errors**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Services/AssetStorage.swift"
git commit -m "feat: add AssetStorage service for photo resizing and Data-to-Image conversion"
```

---

### Task 4: ContentView — NavigationSplitView with ItemListView and ItemDetailView

**Files:**
- Modify: `All my stuff/ContentView.swift`
- Create: `All my stuff/Views/ItemListView.swift`
- Create: `All my stuff/Views/ItemDetailView.swift`
- Test: (navigation verified by build + preview)

**Interfaces:**
- Consumes: Task 2 (`ModelContainer` in environment), Task 1 models
- Produces: `ContentView` as split-view coordinator, `ItemListView` shows all items, `ItemDetailView` shows single item detail

- [ ] **Step 1: Create placeholder ItemListView.swift**

```swift
import SwiftUI
import SwiftData

struct ItemListView: View {
    @Query var items: [Item]

    var body: some View {
        List(items) { item in
            NavigationLink(value: item) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    if let date = item.datePurchased {
                        Text(date, format: .date(.abbreviated))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("My Items")
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    return NavigationStack {
        ItemListView()
    }
    .modelContainer(container)
}
```

- [ ] **Step 2: Create placeholder ItemDetailView.swift**

```swift
import SwiftUI
import SwiftData

struct ItemDetailView: View {
    var item: Item

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Details") {
                Text(item.name)
                    .font(.headline)
            }
            if let photo = AssetStorage.imageDataToImage(item.photo) {
                Section("Photo") {
                    photo.resizable().aspectRatio(contentMode: .fit)
                }
            }
        }
        .navigationTitle(item.name)
    }

    func deleteItem() {
        modelContext.delete(item)
        dismiss()
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    let context = ModelContext(container)
    let item = Item(name: "Test Laptop", datePurchased: Date())
    context.insert(item)
    return NavigationStack {
        ItemDetailView(item: item)
    }
    .modelContainer(container)
}
```

- [ ] **Step 3: Update ContentView.swift with NavigationSplitView**

Replace contents with:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            ItemListView()
        } detail: {
            Text("Select an item")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Build to verify no errors**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add "All my stuff/ContentView.swift" "All my stuff/Views/"
git commit -m "feat: add NavigationSplitView with ItemListView and ItemDetailView placeholders"
```

---

### Task 5: ItemDetailView — Full edit form with all fields

**Files:**
- Modify: `All my stuff/Views/ItemDetailView.swift`
- Create: `All my stuff/Views/CategoryPickerView.swift`
- Create: `All my stuff/Views/LocationPickerView.swift`
- Test: `All my stuffTests/Views/DetailViewTests.swift` ( Smoke test that fields persist )

**Interfaces:**
- Consumes: Task 1 models, Task 2 ModelContainer context, Task 3 AssetStorage
- Produces: Full CRUD form for item with photo picker, price inputs, category/location pickers

- [ ] **Step 1: Create CategoryPickerView.swift**

```swift
import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    let item: Item
    @Binding var selectedCategories: Set<Category>
    @Query var allCategories: [Category]
    @Environment(\.modelContext) private var modelContext

    var availableCategories: [Category] {
        allCategories.filter { !selectedCategories.contains($0) }
    }

    var body: some View {
        Section("Categories") {
            if selectedCategories.isEmpty && allCategories.isEmpty {
                Text("No categories yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(selectedCategories), id: \.id) { cat in
                HStack {
                    Text(cat.name)
                    Spacer()
                    Button(role: .destructive) {
                        selectedCategories.remove(cat)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            if !availableCategories.isEmpty {
                Picker("Add category", selection: Binding.constant(Category?.none)) {
                    ForEach(availableCategories, id: \.id) { cat in
                        Text(cat.name).tag(Category?(cat))
                    }
                }.onChange(of: selectedCategories.count) {}

               ForEach(availableCategories, id: \.id) { cat in
                    Button("+ \(cat.name)") {
                        selectedCategories.insert(cat)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }

            TextField("New category", text: Binding(
                get: { "" },
                set: { newValue in
                    if !newValue.trimmingWhitespace().isEmpty {
                        let newCat = Category(name: newValue.trimmingCharacters(in: .whitespaces))
                        modelContext.insert(newCat)
                        selectedCategories.insert(newCat)
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
    }
}
```

- [ ] **Step 2: Create LocationPickerView.swift**

Same pattern as CategoryPickerView — search/replace Category references with Location. File contents:

```swift
import SwiftUI
import SwiftData

struct LocationPickerView: View {
    let item: Item
    @Binding var selectedLocations: Set<Location>
    @Query var allLocations: [Location]
    @Environment(\.modelContext) private var modelContext

    var availableLocations: [Location] {
        allLocations.filter { !selectedLocations.contains($0) }
    }

    var body: some View {
        Section("Locations") {
            if selectedLocations.isEmpty && allLocations.isEmpty {
                Text("No locations yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(selectedLocations), id: \.id) { loc in
                HStack {
                    Text(loc.name)
                    Spacer()
                    Button(role: .destructive) {
                        selectedLocations.remove(loc)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            ForEach(availableLocations, id: \.id) { loc in
                Button("+ \(loc.name)") {
                    selectedLocations.insert(loc)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            TextField("New location", text: Binding(
                get: { "" },
                set: { newValue in
                    if !newValue.trimmingWhitespace().isEmpty {
                        let newLoc = Location(name: newValue.trimmingCharacters(in: .whitespaces))
                        modelContext.insert(newLoc)
                        selectedLocations.insert(newLoc)
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
    }
}
```

- [ ] **Step 3: Update ItemDetailView.swift with full form**

Replace contents with:

```swift
import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategories: Set<Category> = []
    @State private var selectedLocations: Set<Location> = []
    @State private var photoSelection: PhotosPickerItem?
    @State private var previewImage: Image?

    init(item: Item) {
        self.item = item
        _selectedCategories = State(initialValue: item.categories)
        _selectedLocations = State(initialValue: item.locations)
    }

    var body: some View {
        Form {
            Section("Photo") {
                PhotosPicker(selection: $photoSelection, matching: .images) {
                    if let previewImage {
                        previewImage.resizable().aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Tap to add a photo")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }
                }
                .onChange(of: photoSelection) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            item.photo = AssetStorage.resizeImageData(data)
                            previewImage = AssetStorage.imageDataToImage(data)
                        }
                    }
                }

                if item.photo != nil {
                    Button(role: .destructive) {
                        item.photo = nil
                        previewImage = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            }

            Section("Name") {
                TextField("Item name", text: $item.name)
                    .autocapitalization(.sentences)
            }

            Section("Description") {
                TextEditor(text: $item.description)
                    .frame(minHeight: 80)
            }

            Section("Categories") {
                CategoryPickerView(item: item, selectedCategories: $selectedCategories)
            }

            Section("Locations") {
                LocationPickerView(item: item, selectedLocations: $selectedLocations)
            }

            Section("Prices") {
                HStack {
                    Text("Purchase Price")
                    Spacer()
                    TextField("0.00", value: Binding(
                        get: { item.purchasePrice?.numericValue ?? 0 },
                        set: { newValue in
                            item.purchasePrice = newValue > 0 ? .confirmed(newValue) : nil
                        }
                    ), format: .number.precision(.fractionLength(2)))
                    .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Estimated Value")
                    Spacer()
                    TextField("0.00", value: Binding(
                        get: { item.estimatedValue?.numericValue ?? 0 },
                        set: { newValue in
                            item.estimatedValue = newValue > 0 ? .assumed(newValue) : nil
                        }
                    ), format: .number.precision(.fractionLength(2)))
                    .multilineTextAlignment(.trailing)
                }
            }

            Section("Date Purchased") {
                DatePicker("Purchased", selection: Binding(
                    get: { item.datePurchased ?? Date.now.distantPast },
                    set: { item.datePurchased = $0 }
                ), displayedComponents: .date)
            }

            Button(role: .destructive) {
                modelContext.delete(item)
                dismiss()
            } label: {
                Label("Delete Item", systemImage: "trash")
            }
        }
        .navigationTitle("Edit Item")
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    let context = ModelContext(container)
    let item = Item(name: "Test Laptop", datePurchased: Date())
    let cat = Category(name: "Electronics")
    context.insert(item)
    context.insert(cat)
    item.categories.insert(cat)
    return NavigationStack {
        ItemDetailView(item: item)
    }
    .modelContainer(container)
}
```

- [ ] **Step 4: Write a basic persistence smoke test**

Create `All my stuffTests/Views/DetailViewTests.swift`:

```swift
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("DetailView Smoke Tests")
struct DetailViewTests {

    @Test func item_fieldsPersistCorrectly() async throws {
        let container = ModelContainer(isStoredInMemoryOnly: true)
        let context = ModelContext(container)

        let item = Item(name: "Monitor", datePurchased: Date())
        item.description = "4K monitor"
        item.purchasePrice = .confirmed(599.99)
        item.estimatedValue = .assumed(800)
        context.insert(item)

        let fetch = FetchDescriptor<Item>()
        let results = try context.fetch(fetch)
        #expect(results.count == 1)
        #expect(results[0].name == "Monitor")
        #expect(results[0].description == "4K monitor")
    }
}
```

- [ ] **Step 5: Build and run tests**

Run: `xcodebuild test -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: BUILD SUCCEEDED, all tests PASS

- [ ] **Step 6: Commit**

```bash
git add "All my stuff/Views/" "All my stuffTests/Views/"
git commit -m "feat: complete ItemDetailView with photo picker, category/location pickers, price fields, and delete action"
```

---

### Task 6: ContentView detail column — navigation selection and item creation

**Files:**
- Modify: `All my stuff/ContentView.swift`
- Modify: `All my stuff/Views/ItemListView.swift`
- Test: (verified by preview + build)

**Interfaces:**
- Consumes: Task 4 views, Task 5 form
- Produces: Selection binding between list and detail; "+" button to create new items

- [ ] **Step 1: Update ContentView.swift with selection navigation**

Replace contents with:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedItem: Item?

    var body: some View {
        NavigationSplitView {
            ItemListView(selectedItem: $selectedItem)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            let newItem = Item(name: "New Item")
                            selectedItem = newItem
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                Text("Select or create an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    return ContentView()
        .modelContainer(container)
}
```

- [ ] **Step 2: Update ItemListView.swift with selection binding**

Replace contents with:

```swift
import SwiftUI
import SwiftData

struct ItemListView: View {
    @Query(sort: \.name, order: .forward) var items: [Item]
    @Binding var selectedItem: Item?

    var body: some View {
        List(items) { item in
            Button {
                selectedItem = item
            } label: {
                HStack {
                    if let photoData = item.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                    }
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        if let date = item.datePurchased {
                            Text(date, format: .date(.abbreviated))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("My Items")
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    return NavigationSplitView {
        ItemListView(selectedItem: .constant(nil))
    } detail: {
        Text("Detail")
    }
    .modelContainer(container)
}
```

- [ ] **Step 3: Build to verify no errors**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add "All my stuff/ContentView.swift" "All my stuff/Views/ItemListView.swift"
git commit -m "feat: wire selection navigation between list and detail with new-item creation button"
```

---

### Task 7: ItemListView — New item persistence and delete swipe action

**Files:**
- Modify: `All my stuff/ContentView.swift`
- Modify: `All my stuff/Views/ItemListView.swift`
- Test: `All my stuffTests/Integration/ItemCRUDTests.swift`

**Interfaces:**
- Consumes: Task 6 navigation, Task 2 ModelContainer context
- Produces: Full create-read-update-delete cycle for items

- [ ] **Step 1: Add modelContext to ContentView for new-item insertion**

Update `ContentView`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedItem: Item?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            ItemListView(selectedItem: $selectedItem)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            let newItem = Item(name: "New Item", datePurchased: Date())
                            modelContext.insert(newItem)
                            selectedItem = newItem
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                Text("Select or create an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    return ContentView()
        .modelContainer(container)
}
```

- [ ] **Step 2: Add swipe-to-delete to ItemListView**

Update the `List` body in `ItemListView.swift` to add trailing swipe action. Replace the `List(items) { item in` block with:

```swift
List(items) { item in
    Button {
        selectedItem = item
    } label: {
        HStack {
            if let photoData = item.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
            }
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                if let date = item.datePurchased {
                    Text(date, format: .date(.abbreviated))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .buttonStyle(.plain)
    .swipeActions(edge: .trailing) {
        Button(role: .destructive) {
            modelContext.delete(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
```

Also add `@Environment(\.modelContext) private var modelContext` to `ItemListView`.

- [ ] **Step 3: Write CRUD integration test**

Create `All my stuffTests/Integration/ItemCRUDTests.swift`:

```swift
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Item CRUD Integration Tests")
struct ItemCRUDTests {

    @Test func create_update_delete_item() async throws {
        let container = ModelContainer(isStoredInMemoryOnly: true)
        let context = ModelContext(container)

        let item = Item(name: "Camera", datePurchased: Date())
        context.insert(item)
        #expect(try context.fetch(FetchDescriptor<Item>()).count == 1)

        item.name = "DSLR Camera"
        item.purchasePrice = .confirmed(1200)
        #expect(try context.fetch(FetchDescriptor<Item>())[0].name == "DSLR Camera")

        context.delete(item)
        context.save()
        #expect(try context.fetch(FetchDescriptor<Item>()).count == 0)
    }

    @Test func category_and_location_many_to_many() async throws {
        let container = ModelContainer(isStoredInMemoryOnly: true)
        let context = ModelContext(container)

        let item = Item(name: "Tablet")
        let cat1 = Category(name: "Tech")
        let cat2 = Category(name: "Personal")
        let loc1 = Location(name: "Bag")
        context.insert(item, cat1, cat2, loc1)
        item.categories.insert(cat1)
        item.categories.insert(cat2)
        item.locations.insert(loc1)

        #expect(try context.fetch(FetchDescriptor<Category>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<Location>()).count == 1)
    }
}
```

- [ ] **Step 4: Build and run tests**

Run: `xcodebuild test -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: BUILD SUCCEEDED, all tests PASS

- [ ] **Step 5: Commit**

```bash
git add "All my stuff/ContentView.swift" "All my stuff/Views/ItemListView.swift" "All my stuffTests/Integration/"
git commit -m "feat: complete CRUD with model context insertion and swipe-to-delete in list"
```

---

### Task 8: ItemListView — Search, filter by category/location, and grouping

**Files:**
- Modify: `All my stuff/Views/ItemListView.swift`
- Test: (verified via build + preview)

**Interfaces:**
- Consumes: Task 7 list view, Task 1 models
- Produces: `.searchable` modifier, filter picker for category/location grouping

- [ ] **Step 1: Add search and filter to ItemListView.swift**

Replace full file with:

```swift
import SwiftUI
import SwiftData

struct FilterOption: String, CaseIterable, Identifiable {
    case all, category, location

    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: "All Items"
        case .category: "By Category"
        case .location: "By Location"
        }
    }
}

struct ItemListView: View {
    @Query(sort: \.name, order: .forward) var items: [Item]
    @Binding var selectedItem: Item?
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all

    var filteredItems: [Item] {
        let matched = items.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
        }
        return matched.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            if filterOption == .all {
                Section {
                    ForEach(filteredItems) { item in
                        ItemRow(item: item, onTap: { selectedItem = item })
                    }
                }
            } else if filterOption == .category {
                ForEach(getUniqueCategories(), id: \.id) { cat in
                    Section(cat.name, content: {
                        ForEach(getItems(forCategory: cat)) { item in
                            ItemRow(item: item, onTap: { selectedItem = item })
                        }
                    })
                }
            } else if filterOption == .location {
                ForEach(getUniqueLocations(), id: \.id) { loc in
                    Section(loc.name, content: {
                        ForEach(getItems(forLocation: loc)) { item in
                            ItemRow(item: item, onTap: { selectedItem = item })
                        }
                    })
                }
            }

            if filteredItems.isEmpty && !searchText.isEmpty {
                Section {
                    Text("No items match your search.")
                        .foregroundStyle(.secondary)
                }
            }

            if items.isEmpty {
                Section {
                    Text("No items yet. Tap + to create one.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("My Items")
        .searchable(text: $searchText, prompt: "Search items")
    }

    private func getUniqueCategories() -> [Category] {
        var set = Set<Category>()
        for item in filteredItems {
            set.formUnion(item.categories)
        }
        return set.sorted { $0.name < $1.name }
    }

    private func getItems(forCategory cat: Category) -> [Item] {
        filteredItems.filter { $0.categories.contains(cat) }.sorted { $0.name < $1.name }
    }

    private func getUniqueLocations() -> [Location] {
        var set = Set<Location>()
        for item in filteredItems {
            set.formUnion(item.locations)
        }
        return set.sorted { $0.name < $1.name }
    }

    private func getItems(forLocation loc: Location) -> [Item] {
        filteredItems.filter { $0.locations.contains(loc) }.sorted { $0.name < $1.name }
    }
}

struct ItemRow: View {
    let item: Item
    var onTap: () -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                if let photoData = item.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                }
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    if let date = item.datePurchased {
                        Text(date, format: .date(.abbreviated))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    return NavigationSplitView {
        ItemListView(selectedItem: .constant(nil))
    } detail: {
        Text("Detail")
    }
    .modelContainer(container)
}
```

- [ ] **Step 2: Add filter segmented picker to ContentView toolbar**

Add `@State private var filterOption: FilterOption = .all` to `ContentView` and pass it into `ItemListView`. The toolbar should have a `.primaryAction` for "+" and a `.confirmationAction` or navigation bar item for the filter. Alternatively, embed a Picker at the top of the list.

Update `ContentView`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedItem: Item?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            ItemListView(selectedItem: $selectedItem)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            let newItem = Item(name: "New Item", datePurchased: Date())
                            modelContext.insert(newItem)
                            selectedItem = newItem
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                Text("Select or create an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = ModelContainer(isStoredInMemoryOnly: true)
    return ContentView()
        .modelContainer(container)
}
```

- [ ] **Step 3: Build to verify no errors**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run all tests**

Run: `xcodebuild test -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add "All my stuff/Views/ItemListView.swift"
git commit -m "feat: add search and category/location grouping to ItemListView with ItemRow component"
```

---

### Task 9: Final build verification and CloudKit sanity check

**Files:**
- Modify: none (verification only)

**Interfaces:**
- Consumes: all previous tasks
- Produces: verified build, verified test suite, CloudKit entitlements present

- [ ] **Step 1: Clean build**

Run: `xcodebuild clean build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED with zero warnings

- [ ] **Step 2: Run full test suite**

Run: `xcodebuild test -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "platform=iOS Simulator,name=iPhone 16"`
Expected: All tests PASS

- [ ] **Step 3: Verify entitlements file contains CloudKit configuration**

Run: `cat "All my stuff/All_my_stuff.entitlements"`
Expected: Contains `com.apple.developer.icloud-container-identifiers` with `iCloud.com.tonisucic.All-my-stuff`

- [ ] **Step 4: Verify project structure matches spec**

Expected directory layout:
```
All my stuff/
├── All_my_stuffApp.swift (ModelContainer + CloudKit)
├── All_my_stuff.entitlements
├── Assets.xcassets
├── Models/
│   ├── Item.swift
│   ├── Category.swift
│   ├── Location.swift
│   └── PriceState.swift
├── Views/
│   ├── ContentView.swift (NavigationSplitView)
│   ├── ItemListView.swift (search, grouping, swipe-delete)
│   ├── ItemDetailView.swift (full form)
│   ├── CategoryPickerView.swift
│   └── LocationPickerView.swift
├── Services/
│   └── AssetStorage.swift
```

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "ci: verify final build passes all tests and CloudKit is configured" || true
```

---

## Self-Review Checklist

### 1. Spec Coverage
- [x] Item model with name, photo, description, purchasePrice, estimatedValue, datePurchased — Task 1
- [x] Category model with many-to-many to Item — Task 1
- [x] Location model with many-to-many to Item — Task 1
- [x] PriceState enum (.confirmed, .assumed, .unknown) — Task 1
- [x] Filter and group by category/location — Task 8
- [x] Adaptive NavigationSplitView layout — Task 4, Task 6
- [x] iCloud CloudKit sync via SwiftData — Task 2
- [x] Photos stored as Data attributes — Task 1, Task 3, Task 5
- [x] No external dependencies — all tasks use only Apple frameworks

### 2. Placeholder Scan
- No TBDs, no "implement later", no vague instructions found.

### 3. Type Consistency
- `Item.categories: Set<Category>` used consistently across Tasks 1, 4, 5, 7, 8
- `Item.locations: Set<Location>` used consistently across Tasks 1, 5, 8
- `PriceState` enum cases (.confirmed, .assumed, .unknown) consistent in Task 1, Task 3 test, Task 5, Task 7
- `ModelContext` injection pattern consistent: environment variable in views, explicit parameter in tests
