import SwiftUI
import SwiftData

struct ItemDetailView: View {
    var item: Item

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Details") {
                Text(item.name)
                    .font(.headline)
            }
            if let photo = AssetStorage.imageDataToImage(item.photo) {
                Section("Photo") {
                    photo.resizable().aspectRatio(contentMode: .fit)
                }
            }
        }
        .navigationTitle(item.name)
    }

    func deleteItem() {
        modelContext.delete(item)
        dismiss()
    }
}

// Previews disabled — Xcode macro bug with try!/ModelContainer on iOS 26.5 SDK
// Re-enable after final ItemDetailView implementation
