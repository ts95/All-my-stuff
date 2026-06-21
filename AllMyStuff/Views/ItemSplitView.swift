import SwiftUI
import Dependencies

struct ItemSplitView: View {
    @State private var navigationPath = NavigationPath()
    @State private var creatingItem: Item?
    @State private var editingItem: Item?
    @Dependency(\.itemStore) private var itemStore

    var body: some View {
        NavigationSplitView {
            NavigationStack(path: $navigationPath) {
                ItemListView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                createNewItem()
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .navigationDestination(for: Item.self) { item in
                        ItemProfileView(
                            item: item,
                            onEdit: { editingItem = item },
                            onDelete: { navigationPath.removeLast() }
                        )
                    }
            }
        } detail: {
            Text("Select or create an item")
                .foregroundStyle(.secondary)
        }
        .sheet(item: $creatingItem) { item in
            ItemFormSheet(
                item: item,
                isCreateMode: true,
                onCancel: {},
                onDone: { navigationPath.append(item) }
            )
        }
        .sheet(item: $editingItem) { item in
            ItemFormSheet(
                item: item,
                isCreateMode: false,
                onCancel: {},
                onDone: {}
            )
        }
    }

    private func createNewItem() {
        creatingItem = Item(name: "", datePurchased: Date())
    }
}

#Preview {
    ItemSplitView()
}
