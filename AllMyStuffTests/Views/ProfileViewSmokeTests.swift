import Testing
import Foundation
import SwiftData
@testable import All_my_stuff

@Suite("Profile View Smoke Tests")
struct ProfileViewSmokeTests {

    @Test func item_fields_display_correctly() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Monitor", datePurchased: Date())
        item.notes = "4K monitor"
        let cat = ItemCategory(name: "Electronics")
        let loc = ItemLocation(name: "Desk")
        item.categories = [cat]
        item.locations = [loc]
        context.insert(item)
        context.insert(cat)
        context.insert(loc)
        try context.save()

        let fetch = FetchDescriptor<Item>()
        let results = try context.fetch(fetch)
        #expect(results.count == 1)
        #expect(results[0].name == "Monitor")
        #expect(results[0].notes == "4K monitor")
        #expect(results[0].categories?.count == 1)
        #expect(results[0].locations?.count == 1)
    }
}