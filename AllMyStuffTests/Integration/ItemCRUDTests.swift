import Foundation
import Testing
import SwiftData
@testable import AllMyStuff

@Suite("Item CRUD Integration Tests")
struct ItemCRUDTests {

    @Test func create_update_delete_item() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let store = ItemStore.live(context: ModelContext(container))

            let item = Item(name: "Camera", datePurchased: Date())
            try? store.insert(item)
            try? store.fetchAll()
            #expect(store.items.count == 1)

            item.name = "DSLR Camera"
            item.purchasePrice = 1200
            try? store.save(item)
            #expect(store.items.first?.name == "DSLR Camera")

            try? store.delete(item)
            try? store.fetchAll()
            #expect(store.items.isEmpty)
        }
    }

    @Test func category_and_location_many_to_many() async throws {
        await MainActor.run {
            let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: schema, configurations: [config])
            let itemStore = ItemStore.live(context: ModelContext(container))
            let categoryStore = CategoryStore.live(context: ModelContext(container))
            let locationStore = LocationStore.live(context: ModelContext(container))

            let item = Item(name: "Tablet", datePurchased: Date())
            let cat1 = ItemCategory(name: "Tech")
            let cat2 = ItemCategory(name: "Personal")
            let loc1 = ItemLocation(name: "Bag")

            try? itemStore.insert(item)
            try? categoryStore.insert(cat1)
            try? categoryStore.insert(cat2)
            try? locationStore.insert(loc1)

            item.categories = [cat1, cat2]
            item.locations = [loc1]
            try? itemStore.save(item)

            try? itemStore.fetchAll()
            try? categoryStore.fetchAll()
            try? locationStore.fetchAll()

            #expect(categoryStore.items.count == 2)
            #expect(locationStore.items.count == 1)
        }
    }
}
