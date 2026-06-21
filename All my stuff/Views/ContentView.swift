import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var selectedItem: Item?
    @State private var showCreateSheet = false
    @State private var showEditSheet = false
    @State private var creatingItem: Item?
    @State private var editingItem: Item?
    @Environment(\.modelContext) private var modelContext

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
                            onEdit: {
                                editingItem = item
                                showEditSheet = true
                            },
                            onDelete: {
                                navigationPath.removeLast()
                                selectedItem = nil
                            }
                        )
                        .onAppear { selectedItem = item }
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
                    onDelete: {
                        navigationPath.removeLast()
                        selectedItem = nil
                    }
                )
            } else {
                Text("Select or create an item")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            if let item = creatingItem {
                ItemFormSheet(
                    item: item,
                    isCreateMode: true,
                    onCancel: { showCreateSheet = false },
                    onDone: {
                        navigationPath.append(item)
                        selectedItem = item
                    }
                )
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let item = editingItem {
                ItemFormSheet(
                    item: item,
                    isCreateMode: false,
                    onCancel: { showEditSheet = false },
                    onDone: { showEditSheet = false }
                )
            } else {
                EmptyView()
            }
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
