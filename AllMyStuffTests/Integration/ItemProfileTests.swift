import Foundation
import Testing
import SwiftData
@testable import AllMyStuff

@MainActor
@Suite("Item Profile Model Tests")
struct ItemProfileTests {

    @Test func item_profile_data_persists() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let itemStore = ItemStore.live(context: context)
        let categoryStore = CategoryStore.live(context: context)
        let locationStore = LocationStore.live(context: context)

        let item = Item(name: "Laptop", datePurchased: Date())
        item.notes = "2024 MacBook Pro"
        item.purchasePrice = 1999.99
        item.estimatedValue = 1500
        let cat = ItemCategory(name: "Electronics")
        let loc = ItemLocation(name: "Desk")

        try? itemStore.insert(item)
        try? categoryStore.insert(cat)
        try? locationStore.insert(loc)
        item.categories = [cat]
        item.locations = [loc]
        try? itemStore.save(item)
        try? itemStore.fetchAll()

        #expect(itemStore.items.count == 1)
        #expect(itemStore.items.first?.name == "Laptop")
        #expect(itemStore.items.first?.notes == "2024 MacBook Pro")
        #expect(itemStore.items.first?.categories?.count == 1)
        #expect(itemStore.items.first?.locations?.count == 1)
    }

    @Test func item_profile_no_photo_shows_default_state() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let store = ItemStore.live(context: ModelContext(container))

        let item = Item(name: "Phone", datePurchased: Date())
        try? store.insert(item)
        try? store.save(item)
        try? store.fetchAll()

        #expect(store.items.first?.photo == nil)
    }
}
