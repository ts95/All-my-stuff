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
    makeContentViewPreview()
}
