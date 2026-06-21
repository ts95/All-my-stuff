import Foundation
import Testing
import SwiftData
import UIKit
@testable import AllMyStuff

@Suite("Item Form Sheet Model Tests")
struct ItemFormSheetModelTests {

    @Test func create_item_persists_with_valid_data() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "")
        item.name = "Camera"
        item.notes = "DSLR Camera Body"
        item.purchasePrice = 1200
        item.estimatedValue = 800
        item.datePurchased = Date()
        context.insert(item)
        try context.save()

        let fd = FetchDescriptor<Item>()
        #expect(try context.fetchCount(fd) == 1)
        #expect(try context.fetch(fd)[0].name == "Camera")
    }

    @Test func edit_item_updates_existing_record() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Old Name", datePurchased: Date())
        context.insert(item)
        try context.save()

        item.name = "Updated Name"
        item.notes = "Updated notes"
        item.purchasePrice = 500
        try context.save()

        let fd = FetchDescriptor<Item>()
        let results = try context.fetch(fd)
        #expect(results[0].name == "Updated Name")
        #expect(results[0].notes == "Updated notes")
    }

    @Test func cancel_create_deletes_unsaved_item() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let newItem = Item(name: "")
        context.insert(newItem)
        context.delete(newItem)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
    }

    @Test func photo_resize_preserves_data() async throws {
        await MainActor.run {
            let uiImage = UIImage(systemName: "photo")!
            guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
                Issue.record("failed to create test image data")
                return
            }

            let resized = AssetStorage.resizeImageData(data, maxDimension: 1024)
            #expect(resized != nil)
            if let r = resized {
                #expect(r.count > 0)
            }
        }
    }
}
