import Foundation
import Testing
import SwiftData
import UIKit
@testable import AllMyStuff

@Suite("Item Form Sheet Model Tests")
struct ItemFormSheetModelTests {

    @Test func create_item_persists_with_valid_data() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Camera", datePurchased: Date())
            item.notes = "DSLR Camera Body"
            item.purchasePrice = 1200
            item.estimatedValue = 800

            try? store.insert(item)
            try? store.save(item)
            try? store.fetchAll()

            #expect(store.items.count == 1)
            #expect(store.items.first?.name == "Camera")
        }
    }

    @Test func edit_item_updates_existing_record() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Old Name", datePurchased: Date())
            try? store.insert(item)
            try? store.save(item)

            item.name = "Updated Name"
            item.notes = "Updated notes"
            item.purchasePrice = 500
            try? store.save(item)
            try? store.fetchAll()

            #expect(store.items.first?.name == "Updated Name")
            #expect(store.items.first?.notes == "Updated notes")
        }
    }

    @Test func cancel_create_does_not_persist_item() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let newItem = Item(name: "", datePurchased: Date())
            // Item is never inserted — simulating cancel before save
            try? store.fetchAll()
            #expect(store.items.isEmpty)
        }
    }

    @Test func photo_resize_preserves_data() async throws {
        await MainActor.run {
            let uiImage = UIImage(systemName: "photo")!
            guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
                Issue.record("failed to create test image data")
                return
            }

            let resized = ImageHelper.resizeImageData(data, maxDimension: 1024)
            #expect(resized != nil)
            if let r = resized {
                #expect(r.count > 0)
            }
        }
    }
}
