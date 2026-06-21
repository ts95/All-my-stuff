import SwiftUI
import Dependencies

struct ItemCategoryPickerView: View {
    @Bindable var item: Item
    @Dependency(\.categoryStore) private var categoryStore

    @State private var newCategoryText = ""

    var availableCategories: [ItemCategory] {
        categoryStore.items.filter { !categories.contains($0) }
    }

    var categories: [ItemCategory] {
        get { item.categories ?? [] }
        set { item.categories = newValue }
    }

    var body: some View {
        Section("Categories") {
            if categories.isEmpty && categoryStore.items.isEmpty && newCategoryText.isEmpty {
                Text("No categories yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(categories, id: \.id) { cat in
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

            if !availableCategories.isEmpty {
                ForEach(availableCategories, id: \.id) { cat in
                    HStack {
                        Button {
                            var current = item.categories ?? []
                            current.append(cat)
                            item.categories = current
                        } label: {
                            Label(cat.name, systemImage: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(role: .destructive) {
                            do {
                                try categoryStore.delete(cat)
                            } catch {
                                print("Failed to delete category: \(error)")
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                TextField("New category", text: $newCategoryText)
                    .submitLabel(.done)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addNewCategory()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(newCategoryText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .onSubmit {
                addNewCategory()
            }
        }
        .task {
            do {
                try categoryStore.fetchAll()
            } catch {
                print("Failed to fetch categories: \(error)")
            }
        }
    }

    private func addNewCategory() {
        let name = newCategoryText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let newCat = ItemCategory(name: name)
        do {
            try categoryStore.insert(newCat)
            try categoryStore.save(newCat)
        } catch {
            print("Failed to create category: \(error)")
        }

        var current = item.categories ?? []
        current.append(newCat)
        item.categories = current
        newCategoryText = ""
    }
}
