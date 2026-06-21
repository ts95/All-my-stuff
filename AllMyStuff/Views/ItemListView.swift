import SwiftUI
import Dependencies

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

    var body: some View {
        List {
            if filterOption == .all {
                Section {
                    ForEach(filteredItems, id: \.id) { item in
                        NavigationLink(value: item) {
                            ItemRowView(item: item)
                        }
                    }
                }
            } else if filterOption == .category {
                let grouped = groupedByCategory
                if grouped.isEmpty {
                    Section {
                        Text("No items have categories yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(grouped, id: \.group.id) { groupItems in
                        Section(groupItems.group.name) {
                            ForEach(groupItems.items, id: \.id) { item in
                                NavigationLink(value: item) {
                                    ItemRowView(item: item)
                                }
                            }
                        }
                    }
                }
            } else if filterOption == .location {
                let grouped = groupedByLocation
                if grouped.isEmpty {
                    Section {
                        Text("No items have locations yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(grouped, id: \.group.id) { groupItems in
                        Section(groupItems.group.name) {
                            ForEach(groupItems.items, id: \.id) { item in
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
            do {
                try itemStore.fetchAll()
            } catch {
                print("Failed to fetch items: \(error)")
            }
        }
    }
}

struct ItemRowView: View {
    let item: Item

    var body: some View {
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
}

#Preview {
    ItemListView()
}
