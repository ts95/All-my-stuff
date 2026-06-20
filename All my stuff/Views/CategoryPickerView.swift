import SwiftUI
import SwiftData

struct ItemCategoryPickerView: View {
    @Bindable var item: Item
    @Query var allCategories: [ItemCategory]
    @Environment(\.modelContext) private var modelContext

    var availableCategories: [ItemCategory] {
        allCategories.filter { !categories.contains($0) }
    }

    var categories: [ItemCategory] {
        get { item.categories ?? [] }
        set { item.categories = newValue }
    }

    var body: some View {
        Section("Categories") {
            if categories.isEmpty && allCategories.isEmpty {
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
                        modelContext.insert(newCat)
                        var current = item.categories ?? []
                        current.append(newCat)
                        item.categories = current
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
    }
}
