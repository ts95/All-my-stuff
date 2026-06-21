import Foundation
import Testing
import SwiftData
@testable import AllMyStuff

@Suite("Item CRUD Integration Tests")
struct ItemCRUDTests {

    @Test func create_update_delete_item() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Camera")
        context.insert(item)
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 1)

        item.name = "DSLR Camera"
        item.purchasePrice = 1200
        #expect(try context.fetch(FetchDescriptor<Item>())[0].name == "DSLR Camera")

        context.delete(item)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
    }

    @Test func category_and_location_many_to_many() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Tablet")
        let cat1 = ItemCategory(name: "Tech")
        let cat2 = ItemCategory(name: "Personal")
        let loc1 = ItemLocation(name: "Bag")
        context.insert(item)
        context.insert(cat1)
        context.insert(cat2)
        context.insert(loc1)
        item.categories = [cat1, cat2]
        item.locations = [loc1]

        #expect(try context.fetchCount(FetchDescriptor<ItemCategory>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<ItemLocation>()) == 1)
    }
}
