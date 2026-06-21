import SwiftUI
import Dependencies

struct ItemCategoryPickerView: View {
    @Bindable var item: Item
    @Dependency(\.categoryStore) private var categoryStore

    var availableCategories: [ItemCategory] {
        categoryStore.items.filter { !categories.contains($0) }
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

            ForEach(availableCategories, id: \.id) { cat in
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
                        do {
                            try categoryStore.insert(newCat)
                            try categoryStore.save(newCat)
                        } catch {
                            print("Failed to create category: \(error)")
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
            do {
                try categoryStore.fetchAll()
            } catch {
                print("Failed to fetch categories: \(error)")
            }
        }
    }
}
