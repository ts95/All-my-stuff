import Foundation
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Item Profile Model Tests")
struct ItemProfileTests {

    @Test func item_profile_data_persists() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Laptop", datePurchased: Date())
        item.notes = "2024 MacBook Pro"
        item.purchasePrice = 1999.99
        item.estimatedValue = 1500
        let cat = ItemCategory(name: "Electronics")
        let loc = ItemLocation(name: "Desk")
        item.categories = [cat]
        item.locations = [loc]

        context.insert(item)
        context.insert(cat)
        context.insert(loc)
        try context.save()

        let fd = FetchDescriptor<Item>()
        let results = try context.fetch(fd)
        #expect(results.count == 1)
        #expect(results[0].name == "Laptop")
        #expect(results[0].notes == "2024 MacBook Pro")
        #expect(results[0].categories?.count == 1)
        #expect(results[0].locations?.count == 1)
    }

    @Test func item_profile_no_photo_shows_default_state() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Phone", datePurchased: Date())
        context.insert(item)
        try context.save()

        let fd = FetchDescriptor<Item>()
        let results = try context.fetch(fd)
        #expect(results[0].photo == nil)
    }
}
