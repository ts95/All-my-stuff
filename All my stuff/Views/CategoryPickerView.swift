import SwiftUI
import SwiftData

struct ItemCategoryPickerView: View {
    @Bindable var item: Item
    @Query var allCategories: [ItemCategory]
    @Environment(\.modelContext) private var modelContext

    var availableCategories: [ItemCategory] {
        allCategories.filter { !item.categories.contains($0) }
    }

    var body: some View {
        Section("Categories") {
            if item.categories.isEmpty && allCategories.isEmpty {
                Text("No categories yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(item.categories, id: \.persistentModelID) { cat in
                HStack {
                    Text(cat.name)
                    Spacer()
                    Button(role: .destructive) {
                        item.categories.removeAll { $0 == cat }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            ForEach(availableCategories, id: \.persistentModelID) { cat in
                Button("+ \(cat.name)") {
                    item.categories.append(cat)
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
                        item.categories.append(newCat)
                    }
                }
            ))
            .submitLabel(.done)
            .textFieldStyle(.roundedBorder)
        }
    }
}
