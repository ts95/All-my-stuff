//
//  DataModelTests.swift
//  All my stuffTests
//
//  Created by Toni Sucic on 20/06/2026.
//

import Foundation
import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Data Model Tests")
struct DataModelTests {

    // ModelContext(.inMemory()) was removed in iOS 26 — use Schema + ModelConfiguration instead
    private var container: ModelContainer!
    private var context: ModelContext!

    init() {
        let schema = Schema([Item.self, ItemCategory.self, ItemLocation.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    @Test func item_createsWithRequiredFields() async throws {
        let item = Item(name: "Laptop", datePurchased: Date())
        #expect(item.name == "Laptop")
        #expect(item.notes.isEmpty)
        #expect(item.photo == nil)
        #expect(item.purchasePrice == nil)
    }

    @Test func category_createsWithName() async throws {
        let cat = ItemCategory(name: "Electronics")
        context.insert(cat)
        let fd = FetchDescriptor<ItemCategory>()
        #expect(try context.fetchCount(fd) == 1)
    }

    @Test func location_createsWithName() async throws {
        let loc = ItemLocation(name: "Office Desk")
        context.insert(loc)
        let fd = FetchDescriptor<ItemLocation>()
        #expect(try context.fetchCount(fd) == 1)
    }

    @Test func item_linksToManyCategories() async throws {
        let laptop = Item(name: "Laptop", datePurchased: Date())
        let electronics = ItemCategory(name: "Electronics")
        let work = ItemCategory(name: "Work")
        laptop.categories = [electronics, work]
        #expect(laptop.categories?.count == 2)
    }

    @Test func item_linksToManyLocations() async throws {
        let phone = Item(name: "Phone", datePurchased: Date())
        let office = ItemLocation(name: "Office")
        let home = ItemLocation(name: "Home")
        phone.locations = [office, home]
        #expect(phone.locations?.count == 2)
    }

    @Test func priceState_confirmedValue() async throws {
        let price = PriceState.confirmed(999.99)
        #expect(price.displayValue == "999.99")
        #expect(price.numericValue == 999.99)
    }

    @Test func priceState_assumedValue() async throws {
        let price = PriceState.assumed(500)
        #expect(price.displayValue == "500.00")
        #expect(price.numericValue == 500)
    }

    @Test func priceState_unknown() async throws {
        let price = PriceState.unknown
        #expect(price.displayValue == "Unknown")
        #expect(price.numericValue == nil)
    }
}
