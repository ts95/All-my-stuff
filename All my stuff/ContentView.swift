import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            ItemListView()
        } detail: {
            Text("Select an item")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
