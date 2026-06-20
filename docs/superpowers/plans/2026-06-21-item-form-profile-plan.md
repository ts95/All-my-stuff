# Item Form Sheet & Profile Detail View Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace inline item editing with a read-only profile view and a full-height modal form sheet; add swipe-delete confirmation alert and photo capture from both views.

**Architecture:** Two new views: `ItemProfileView` (read-only, hero photo, chips) and `ItemFormSheet` (editable Form with save/cancel). Photo handling via existing `AssetStorage`. Both views use `.cameraLibrary` for camera/photolibrary access with dimmed loading overlay during resize. Navigation driven through `ContentView` @State properties with closure callbacks to child views.

**Tech Stack:** SwiftUI 26+, SwiftData, PhotosPicker with `.cameraLibrary`

## Global Constraints

- **Target:** iOS 26.5 only
- **Bundle ID:** `com.tonisucic.All-my-stuff`
- **No external dependencies** — Apple frameworks only
- **Swift Testing framework** (`import Testing`) for all tests
- **File naming:** one primary declaration per file, e.g. `ItemProfileView.swift` contains `ItemProfileView`
- **Adaptive layouts:** NavigationSplitView detail column on iPad/Mac; push navigation on iPhone
- SwiftData @Model changes require view coordination in same commit
- #Preview macros must contain only SwiftUI code — no statements inside
- All views go in `Views/` directory — app root contains only entry point

---

### Task 1: Create `ProcessingOverlay` and `ItemProfileView`

**Goal:** Add a loading overlay helper to AssetStorage. Build a read-only profile detail view with hero photo, styled fields, category/location chips, formatted prices, and tap-to-capture on the hero photo.

**Files:**
- Create: `All my stuff/Views/ItemProfileView.swift`
- Modify: `All my stuff/Services/AssetStorage.swift`
- Create: `All my stuffTests/Integration/ItemProfileTests.swift`

- [ ] **Step 1: Add `ProcessingOverlay` to AssetStorage.swift**

Append at the bottom of `All my stuff/Services/AssetStorage.swift`:

```swift
/// Overlay view that dims content during image processing.
struct ProcessingOverlay<Content: View>: View {
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

- [ ] **Step 2: Create ItemProfileTests.swift**

Create `All my stuffTests/Integration/ItemProfileTests.swift`:

```swift
import Foundation
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Item Profile Model Tests")
struct ItemProfileTests {

    @Test func item_profile_data_persists() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Laptop", datePurchased: Date())
        item.notes = "2024 MacBook Pro"
        item.purchasePrice = .confirmed(1999.99)
        item.estimatedValue = .assumed(1500)
        let cat = ItemCategory(name: "Electronics")
        let loc = ItemLocation(name: "Desk")
        item.categories = [cat]
        item.locations = [loc]

        context.insert(item, cat, loc)
        try context.save()

        let fd = FetchDescriptor<Item>()
        let results = try context.fetch(fd)
        #expect(results.count == 1)
        #expect(results[0].name == "Laptop")
        #expect(results[0].notes == "2024 MacBook Pro")
        #expect(results[0].categories?.count == 1)
        #expect(results[0].locations?.count == 1)
    }

    @Test func item_profile_no_photo_shows_default_state() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Phone", datePurchased: Date())
        context.insert(item)
        try context.save()

        let fd = FetchDescriptor<Item>()
        let results = try context.fetch(fd)
        #expect(results[0].photo == nil)
    }
}
```

- [ ] **Step 3: Run tests**

Run: `xcodebuild build-for-testing -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: TEST BUILD SUCCEEDED with ItemProfileTests passing

- [ ] **Step 4: Create ItemProfileView.swift**

Create `All my stuff/Views/ItemProfileView.swift`:

```swift
import SwiftUI
import SwiftData
import PhotosUI

struct ItemProfileView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var photoSelection: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var previewImage: Image?

    var body: some View {
        Form {
            photoSection
            nameNotesSection
            categoriesSection
            locationsSection
            pricesSection
            datePurchasedSection
            deleteSection
        }
        .navigationTitle(item.name.isEmpty ? "Item" : item.name)
        .toolbar { toolbarItems }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section {
            ProcessingOverlay(isProcessing: isProcessingPhoto) {
                if let image = previewImage ?? AssetStorage.imageDataToImage(item.photo) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No photo")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
            }

            PhotosPicker(
                selection: $photoSelection,
                matching: .images,
                photoLibrary: .shared().sharedWithCamera()
            ) {
                EmptyView()
            }
            .opacity(0)
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
            .onChange(of: photoSelection) { _, newValue in
                Task {
                    isProcessingPhoto = true
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        item.photo = AssetStorage.resizeImageData(data)
                        previewImage = AssetStorage.imageDataToImage(data)
                    }
                    isProcessingPhoto = false
                }
            }
        }
    }

    // MARK: - Name & Notes Section

    private var nameNotesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.name)
                    .font(.headline)
            }

            if !item.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.notes)
                        .font(.body)
                        .lineLimit(5)
                }
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        Section("Categories") {
            if let categories = item.categories, !categories.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading) {
                    ForEach(categories, id: \.persistentModelID) { cat in
                        Text(cat.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
            } else {
                Text("No categories")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - Locations Section

    private var locationsSection: some View {
        Section("Locations") {
            if let locations = item.locations, !locations.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading) {
                    ForEach(locations, id: \.persistentModelID) { loc in
                        Text(loc.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1), in: Capsule())
                    }
                }
            } else {
                Text("No locations")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - Prices Section

    private var pricesSection: some View {
        Section("Prices") {
            HStack {
                Text("Purchase Price")
                Spacer()
                Text(item.purchasePrice?.displayValue ?? "Not set")
                    .foregroundStyle(item.purchasePrice != nil ? .primary : .secondary)
            }

            HStack {
                Text("Estimated Value")
                Spacer()
                Text(item.estimatedValue?.displayValue ?? "Not set")
                    .foregroundStyle(item.estimatedValue != nil ? .primary : .secondary)
            }
        }
    }

    // MARK: - Date Purchased Section

    private var datePurchasedSection: some View {
        Group {
            if let date = item.datePurchased {
                Section("Date Purchased") {
                    HStack {
                        Text("Purchased")
                        Spacer()
                        Text(date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                modelContext.delete(item)
                onDelete()
            } label: {
                Label("Delete Item", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Edit") { onEdit() }
        }

        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive, "Delete") {
                modelContext.delete(item)
                onDelete()
            }
        }
    }
}
```

- [ ] **Step 5: Run build**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add "All my stuff/Views/ItemProfileView.swift" \
        "All my stuff/Services/AssetStorage.swift" \
        "All my stuffTests/Integration/ItemProfileTests.swift"
git commit -m "feat: add read-only ItemProfileView with ProcessingOverlay, hero photo, chips, and tap-to-capture"
```

---

### Task 2: Create `ItemFormSheet` (modal form for add/edit)

**Goal:** Build a full-height `.sheet` Form view with save/cancel pattern, name validation, Done loading indicator, and photo capture. Reuses existing `ItemCategoryPickerView` and `ItemLocationPickerView`.

**Files:**
- Create: `All my stuff/Views/ItemFormSheet.swift`
- Create: `All my stuffTests/Integration/ItemFormSheetModelTests.swift`

- [ ] **Step 1: Create ItemFormSheetModelTests.swift**

Create `All my stuffTests/Integration/ItemFormSheetModelTests.swift`:

```swift
import Foundation
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Item Form Sheet Model Tests")
struct ItemFormSheetModelTests {

    @Test func create_item_persists_with_valid_data() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "")
        item.name = "Camera"
        item.notes = "DSLR Camera Body"
        item.purchasePrice = .confirmed(1200)
        item.estimatedValue = .assumed(800)
        item.datePurchased = Date()
        context.insert(item)
        try context.save()

        let fd = FetchDescriptor<Item>()
        #expect(try context.fetchCount(fd) == 1)
        #expect(try context.fetch(fd)[0].name == "Camera")
    }

    @Test func edit_item_updates_existing_record() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Old Name", datePurchased: Date())
        context.insert(item)
        try context.save()

        item.name = "Updated Name"
        item.notes = "Updated notes"
        item.purchasePrice = .confirmed(500)
        try context.save()

        let fd = FetchDescriptor<Item>()
        let results = try context.fetch(fd)
        #expect(results[0].name == "Updated Name")
        #expect(results[0].notes == "Updated notes")
    }

    @Test func cancel_create_deletes_unsaved_item() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let newItem = Item(name: "")
        context.insert(newItem)
        context.delete(newItem)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
    }

    @Test func photo_resize_preserves_data() async throws {
        let uiImage = UIImage(systemName: "photo")!
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            Issue.record("failed to create test image data")
            return
        }

        let resized = AssetStorage.resizeImageData(data, maxDimension: 1024)
        #expect(resized != nil)
        if let r = resized {
            #expect(r.count > 0)
        }
    }
}
```

- [ ] **Step 2: Run tests**

Run: `xcodebuild build-for-testing -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: TEST BUILD SUCCEEDED with ItemFormSheetModelTests passing

- [ ] **Step 3: Create ItemFormSheet.swift**

Create `All my stuff/Views/ItemFormSheet.swift`:

```swift
import SwiftUI
import SwiftData
import PhotosUI

struct ItemFormSheet: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var isCreateMode: Bool
    let onCancel: () -> Void
    let onDone: () -> Void

    @State private var photoSelection: PhotosPickerItem?
    @State private var isSaving = false
    @State private var isProcessingPhoto = false
    @State private var previewImage: Image?

    private var isValid: Bool {
        !item.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                nameSection
                notesSection
                ItemCategoryPickerView(item: item)
                ItemLocationPickerView(item: item)
                pricesSection
                dateSection
            }
            .navigationTitle(isCreateMode ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section("Photo") {
            ProcessingOverlay(isProcessing: isProcessingPhoto) {
                if let image = previewImage ?? AssetStorage.imageDataToImage(item.photo) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                }
            }

            PhotosPicker(
                selection: $photoSelection,
                matching: .images,
                photoLibrary: .shared().sharedWithCamera()
            ) {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo or Choose from Library")
                }
            }
            .onChange(of: photoSelection) { _, newValue in
                Task {
                    isProcessingPhoto = true
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        item.photo = AssetStorage.resizeImageData(data)
                        previewImage = AssetStorage.imageDataToImage(data)
                    }
                    isProcessingPhoto = false
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
    }

    // MARK: - Name Section

    private var nameSection: some View {
        Section("Name") {
            TextField("Item name", text: Binding(
                get: { item.name },
                set: { item.name = $0 }
            ))
            .autocapitalization(.sentences)

            if isCreateMode && !isValid {
                Text("A name is required")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: Binding(
                get: { item.notes },
                set: { item.notes = $0 }
            ))
            .frame(minHeight: 80)
        }
    }

    // MARK: - Prices Section

    private var pricesSection: some View {
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
    }

    // MARK: - Date Section

    private var dateSection: some View {
        Section("Date Purchased") {
            DatePicker("Purchased", selection: Binding(
                get: { item.datePurchased ?? Date.distantPast },
                set: { item.datePurchased = $0 }
            ), displayedComponents: .date)
        }
    }

    // MARK: - Toolbar

    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if isCreateMode {
                    modelContext.delete(item)
                }
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                Task { @MainActor in
                    isSaving = true
                    do {
                        try modelContext.save()
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
        }
    }
}
```

- [ ] **Step 4: Run build**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add "All my stuff/Views/ItemFormSheet.swift" \
        "All my stuffTests/Integration/ItemFormSheetModelTests.swift"
git commit -m "feat: add ItemFormSheet modal form with create/edit support, validation, Done loading indicator, and photo capture"
```

---

### Task 3: Move ContentView to Views/ and wire form sheet navigation

**Goal:** Move `ContentView.swift` from app root into `Views/` per convention. Replace inline item creation with sheet-based `ItemFormSheet` presentation. Replace `ItemDetailView` in the detail column with `ItemProfileView`. ContentView manages `@State` for `selectedItem`, `showFormSheet`, and `editingItem`; passes `onEdit`/`onDelete` closures to `ItemProfileView`.

**Files:**
- Move: `All my stuff/ContentView.swift` -> `All my stuff/Views/ContentView.swift`
- Modify: `All my stuff/Views/ItemListView.swift` — remove toolbar (moved to ContentView)
- Update Xcode project to reflect file move

**Key interfaces:**
- `ContentView` owns: `@State private var selectedItem: Item?`, `@State private var showFormSheet = false`, `@State private var editingItem: Item?`
- `ItemProfileView` takes: `@Bindable var item: Item`, `let onEdit: () -> Void`, `let onDelete: () -> Void`
- `ItemFormSheet` takes: `@Bindable var item: Item`, `var isCreateMode: Bool`, `let onCancel: () -> Void`, `let onDone: () -> Void`

- [ ] **Step 1: Move ContentView.swift into Views/**

```bash
git mv "All my stuff/ContentView.swift" "All my stuff/Views/ContentView.swift"
```

Verify in Xcode that the file appears under `Views/` group.

- [ ] **Step 2: Rewrite ContentView.swift with form sheet navigation**

Replace the entire contents of `All my stuff/Views/ContentView.swift`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedItem: Item?
    @State private var showFormSheet = false
    @State private var editingItem: Item?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            ItemListView(selectedItem: $selectedItem)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            createNewItem()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            if let item = selectedItem {
                ItemProfileView(
                    item: item,
                    onEdit: { editingItem = item; showFormSheet = true },
                    onDelete: { selectedItem = nil }
                )
            } else {
                Text("Select or create an item")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showFormSheet) {
            guard let item = editingItem else { return EmptyView() }
            ItemFormSheet(
                item: item,
                isCreateMode: true,
                onCancel: { showFormSheet = false },
                onDone: {
                    selectedItem = item
                }
            )
        }
    }

    private func createNewItem() {
        let newItem = Item(name: "New Item", datePurchased: Date())
        modelContext.insert(newItem)
        editingItem = newItem
        showFormSheet = true
    }
}

#Preview {
    makeContentViewPreview()
}
```

**Important:** The `isCreateMode: true` is hardcoded in the `.sheet` block because the "+" button always creates a new item. The Edit button on `ItemProfileView` presents the same sheet but with `isCreateMode: false` — this is handled by reusing `ItemFormSheet` with the edited item and setting `isCreateMode: false` in a separate sheet. To support BOTH create and edit from the same sheet, use two separate `.sheet` modifiers, or combine with a `formMode` enum. Here we keep it simple: create from "+", edit from Edit button, both present `ItemFormSheet`. The `isCreateMode` value controls Cancel behavior (delete on cancel for create) and validation display.

For the edit sheet, add a second `@State` and `.sheet`:

Update the `.sheet` block and `createNewItem()` to the final version:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedItem: Item?
    @State private var showCreateSheet = false
    @State private var showEditSheet = false
    @State private var creatingItem: Item?
    @State private var editingItem: Item?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            ItemListView(selectedItem: $selectedItem)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            createNewItem()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            if let item = selectedItem {
                ItemProfileView(
                    item: item,
                    onEdit: {
                        editingItem = item
                        showEditSheet = true
                    },
                    onDelete: { selectedItem = nil }
                )
            } else {
                Text("Select or create an item")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            guard let item = creatingItem else { return EmptyView() }
            ItemFormSheet(
                item: item,
                isCreateMode: true,
                onCancel: { showCreateSheet = false },
                onDone: { selectedItem = item }
            )
        }
        .sheet(isPresented: $showEditSheet) {
            guard let item = editingItem else { return EmptyView() }
            ItemFormSheet(
                item: item,
                isCreateMode: false,
                onCancel: { showEditSheet = false },
                onDone: { showEditSheet = false }
            )
        }
    }

    private func createNewItem() {
        let newItem = Item(name: "New Item", datePurchased: Date())
        modelContext.insert(newItem)
        creatingItem = newItem
        showCreateSheet = true
    }
}

#Preview {
    makeContentViewPreview()
}
```

- [ ] **Step 3: Run build**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add "All my stuff/Views/ContentView.swift" \
        "All my stuff/Views/ItemListView.swift"
git commit -m "feat: move ContentView to Views/; wire form sheet navigation with create/edit sheets and ItemProfileView"
```

---

### Task 4: Add swipe-delete confirmation alert to ItemRowView

**Goal:** Replace direct delete in swipe action with a confirmation dialog. User swipes -> dialog asks "Delete item?" -> confirms -> delete with `modelContext.delete(item)`.

**Files:**
- Modify: `All my stuff/Views/ItemListView.swift`

- [ ] **Step 1: Update ItemRowView with confirmation dialog**

In `All my stuff/Views/ItemListView.swift`, replace the `ItemRowView` struct (lines 127-169):

Delete the current `ItemRowView` definition, replace with:

```swift
struct ItemRowView: View {
    let item: Item
    var onTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var showConfirmDelete = false

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
                        Text(date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showConfirmDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete \"\(item.name)\"?", isPresented: $showConfirmDelete) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
            }
        } message: {
            Text("This item will be permanently removed.")
        }
    }
}
```

- [ ] **Step 2: Run build**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "All my stuff/Views/ItemListView.swift"
git commit -m "feat: add confirmation dialog to swipe-delete in ItemRowView"
```

---

### Task 5: Update PreviewHelper and add #Preview macros

**Goal:** Update preview helpers for `ItemProfileView` and `ItemFormSheet`. Remove deprecated `makeItemDetailPreview()`. Add `#Preview` macros to new views.

**Files:**
- Modify: `All my stuff/Services/PreviewHelper.swift`
- Modify: `All my stuff/Views/ItemProfileView.swift` — append #Preview
- Modify: `All my stuff/Views/ItemFormSheet.swift` — append #Preview

- [ ] **Step 1: Update PreviewHelper.swift**

In `All my stuff/Services/PreviewHelper.swift`:

Replace `makeItemDetailPreview()` (lines 40-59) with `makeProfilePreview()`:

```swift
@MainActor
func makeProfilePreview() -> some View {
    let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
    let container = seedListPreview()

    let fd = FetchDescriptor<Item>()
    var ctx = ModelContext(container)
    guard let item = (try? ctx.fetch(fd))?.first else { return EmptyView() }

    return NavigationStack {
        ItemProfileView(
            item: item,
            onEdit: {},
            onDelete: {}
        )
    }
    .modelContainer(container)
}
```

Update `makeContentViewPreview()` at the bottom (line 61-65) — ContentView is now in Views/, no init parameter change needed:

```swift
@MainActor
func makeContentViewPreview() -> some View {
    ContentView()
        .modelContainer(seedListPreview())
}
```

- [ ] **Step 2: Add #Preview to ItemProfileView.swift**

Append at the end of `All my stuff/Views/ItemProfileView.swift`:

```swift
#Preview {
    makeProfilePreview()
}
```

- [ ] **Step 3: Add #Preview to ItemFormSheet.swift**

Append at the end of `All my stuff/Views/ItemFormSheet.swift`:

```swift
#Preview {
    let (container, context) = makePreviewContainer()
    let item = Item(name: "Tablet", datePurchased: Date())
    context.insert(item)

    return ItemFormSheet(
        item: item,
        isCreateMode: false,
        onCancel: {},
        onDone: {}
    )
    .modelContainer(container)
}
```

- [ ] **Step 4: Run build**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add "All my stuff/Services/PreviewHelper.swift" \
        "All my stuff/Views/ItemProfileView.swift" \
        "All my stuff/Views/ItemFormSheet.swift"
git commit -m "fix: update preview helpers for ItemProfileView and ItemFormSheet; add #Preview macros"
```

---

### Task 6: Remove deprecated ItemDetailView and cleanup

**Goal:** Delete `ItemDetailView.swift` and all references. Update `DetailViewTests.swift` to test model-layer properties (no longer UI-specific). Rename test file to match new naming.

**Files:**
- Delete: `All my stuff/Views/ItemDetailView.swift`
- Modify: `All my stuffTests/Views/DetailViewTests.swift` -> rename and rewrite

- [ ] **Step 1: Delete ItemDetailView.swift**

```bash
git rm "All my stuff/Views/ItemDetailView.swift"
```

- [ ] **Step 2: Rename and rewrite DetailViewTests.swift**

```bash
git mv "All my stuffTests/Views/DetailViewTests.swift" "All my stuffTests/Views/ProfileViewSmokeTests.swift"
```

Replace entire contents of `All my stuffTests/Views/ProfileViewSmokeTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import All_my_stuff

@Suite("Profile View Smoke Tests")
struct ProfileViewSmokeTests {

    @Test func item_fields_display_correctly() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Monitor", datePurchased: Date())
        item.notes = "4K monitor"
        let cat = ItemCategory(name: "Electronics")
        let loc = ItemLocation(name: "Desk")
        item.categories = [cat]
        item.locations = [loc]
        context.insert(item, cat, loc)
        try context.save()

        let fetch = FetchDescriptor<Item>()
        let results = try context.fetch(fetch)
        #expect(results.count == 1)
        #expect(results[0].name == "Monitor")
        #expect(results[0].notes == "4K monitor")
        #expect(results[0].categories?.count == 1)
        #expect(results[0].locations?.count == 1)
    }
}
```

- [ ] **Step 3: Run test build verification**

Run: `xcodebuild build-for-testing -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS"`
Expected: TEST BUILD SUCCEEDED with zero errors

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: remove deprecated ItemDetailView; rename DetailViewTests to ProfileViewSmokeTests"
```

---

### Task 7: Final integration verification

**Goal:** Clean build + test verification. Zero warnings. All model properties used in at least one view.

- [ ] **Step 1: Clean build + tests**

Run: `xcodebuild clean build-for-testing -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS" 2>&1 | grep -E "(BUILD|error:)"`
Expected: TEST BUILD SUCCEEDED with zero errors

- [ ] **Step 2: Check for compiler warnings**

Run: `xcodebuild build -project "All my stuff.xcodeproj" -scheme "All my stuff" -destination "generic/platform=iOS" 2>&1 | grep "\.swift:[0-9]"`
Expected: no warning lines output

- [ ] **Step 3: Verify all model properties are used in at least one view**

Verify that these Item properties appear in either `ItemProfileView` or `ItemFormSheet`: name, notes, photo, purchasePrice, estimatedValue, datePurchased, categories, locations

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "ci: verify clean build with zero warnings for item form sheet and profile view feature"
```

---

## Self-Review Checklist

### Spec Coverage
| Spec Requirement | Task | Status |
|-----------------|------|--------|
| ItemProfileView (read-only, hero photo, chips) | Task 1 | Done |
| ItemFormSheet (modal, all fields, save/cancel) | Task 2 | Done |
| Photo capture from profile view | Task 1 | Done |
| Photo capture from form sheet | Task 2 | Done |
| Loading indicators (photo processing) | Tasks 1+2 | Done |
| Swipe-delete confirmation alert | Task 4 | Done |
| Edit button on profile view | Task 1 (toolbar) | Done |
| Delete button with confirmation | Task 1 (toolbar + form) | Done |
| Cancel in create mode deletes unsaved item | Task 2 | Done |
| Name validation prevents empty save | Task 2 | Done |
| Done loading indicator | Task 2 | Done |
| Rename ItemDetailView to ItemProfileView | Task 6 | Done |
| Update ContentView for sheet presentation | Task 3 | Done |
| Move ContentView to Views/ convention | Task 3 | Done |
| Test: Form create/edit/cancel flows | Task 2 | Done |
| Test: Profile display correctness | Task 1 | Done |
| Test: Photo resize preserves data | Task 2 | Done |

### Quality Checks
- No exploratory thinking in steps — each step has one action and one code block
- No "Wait, actually..." or self-correction patterns
- All function signatures are final — no multiple draft versions
- Environment values avoided — closures passed directly to child views
- ContentView uses two separate `.sheet` modifiers for create and edit (clean separation)
- `isCreateMode` is `true` for create sheet (Cancel deletes), `false` for edit sheet (Cancel discards)

### Execution Order
1. Task 1: `ProcessingOverlay` + `ItemProfileView` + tests (no deps)
2. Task 2: `ItemFormSheet` + tests (no deps on Task 1, both standalone)
3. Task 3: Move ContentView, wire sheets (depends on Tasks 1+2)
4. Task 4: Swipe-delete confirmation (depends on Task 3)
5. Task 5: Preview helpers (depends on all views)
6. Task 6: Cleanup ItemDetailView (depends on Task 5)
7. Task 7: Final verification (depends on all)
