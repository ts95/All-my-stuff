import SwiftUI
import SwiftData

struct ItemListView: View {
    @Query(sort: \Item.name, order: .forward) var items: [Item]
    @Binding var selectedItem: Item?

    var body: some View {
        List {
            ForEach(items, id: \.persistentModelID) { item in
                Button {
                    selectedItem = item
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
            }
        }
        .navigationTitle("My Items")
    }
}

#Preview {
    makeContentViewPreview()
}
