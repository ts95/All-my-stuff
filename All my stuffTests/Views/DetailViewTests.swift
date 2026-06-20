import Testing
import Foundation
import SwiftData
@testable import All_my_stuff

@Suite("DetailView Smoke Tests")
struct DetailViewTests {

    // ModelContext(.inMemory()) was removed in iOS 26 — use Schema + ModelConfiguration instead
    @Test func item_fieldsPersistCorrectly() async throws {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(name: "Monitor", datePurchased: Date())
        item.notes = "4K monitor"
        item.purchasePrice = .confirmed(599.99)
        item.estimatedValue = .assumed(800)
        context.insert(item)

        let fetch = FetchDescriptor<Item>()
        let results = try context.fetch(fetch)
        #expect(results.count == 1)
        #expect(results[0].name == "Monitor")
        #expect(results[0].notes == "4K monitor")
    }
}
