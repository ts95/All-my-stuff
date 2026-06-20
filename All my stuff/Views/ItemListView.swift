import SwiftUI
import SwiftData

enum FilterOption: String, CaseIterable, Identifiable {
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
    @Query(sort: \Item.name, order: .forward) var items: [Item]
    @Binding var selectedItem: Item?
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all

    var filteredItems: [Item] {
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
                        ItemRowView(item: item, onTap: { selectedItem = item })
                    }
                }
            } else if filterOption == .category {
                let categories = getUniqueCategories()
                if categories.isEmpty {
                    Section {
                        Text("No items have categories yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(categories, id: \.persistentModelID) { cat in
                        Section(cat.name) {
                            let categoryItems = filteredItems.filter { ($0.categories ?? []).contains(cat) }.sorted { $0.name < $1.name }
                            ForEach(categoryItems, id: \.persistentModelID) { item in
                                ItemRowView(item: item, onTap: { selectedItem = item })
                            }
                        }
                    }
                }
            } else if filterOption == .location {
                let locations = getUniqueLocations()
                if locations.isEmpty {
                    Section {
                        Text("No items have locations yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(locations, id: \.persistentModelID) { loc in
                        Section(loc.name) {
                            let locationItems = filteredItems.filter { ($0.locations ?? []).contains(loc) }.sorted { $0.name < $1.name }
                            ForEach(locationItems, id: \.persistentModelID) { item in
                                ItemRowView(item: item, onTap: { selectedItem = item })
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

            if items.isEmpty {
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
    }

    private func getUniqueCategories() -> [ItemCategory] {
        var set = Set<ItemCategory>()
        for item in filteredItems {
            for cat in item.categories ?? [] {
                set.insert(cat)
            }
        }
        return set.sorted { $0.name < $1.name }
    }

    private func getUniqueLocations() -> [ItemLocation] {
        var set = Set<ItemLocation>()
        for item in filteredItems {
            for loc in item.locations ?? [] {
                set.insert(loc)
            }
        }
        return set.sorted { $0.name < $1.name }
    }
}

struct ItemRowView: View {
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
                modelContext.delete(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    makeContentViewPreview()
}
