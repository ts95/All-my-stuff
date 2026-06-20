import SwiftUI
import SwiftData

struct ItemListView: View {
    @Query var items: [Item]

    var body: some View {
        List {
            ForEach(items, id: \.persistentModelID) { item in
                NavigationLink(value: item) {
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
        .navigationTitle("My Items")
    }
}

// Previews disabled — Xcode macro bug with try!/ModelContainer on iOS 26.5 SDK
