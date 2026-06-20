import SwiftUI
import SwiftData

struct ItemListView: View {
    @Query(sort: \Item.name, order: .forward) var items: [Item]
    @Binding var selectedItem: Item?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(items, id: \.persistentModelID) { item in
                ItemRowView(item: item, onTap: { selectedItem = item })
            }
        }
        .navigationTitle("My Items")
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
