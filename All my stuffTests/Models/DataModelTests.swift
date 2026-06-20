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
        var price = PriceState.confirmed(999.99)
        switch price {
        case .confirmed(let value):
            #expect(value == 999.99)
        default:
            Issue.record("expected confirmed")
        }
    }

    @Test func priceState_assumedValue() async throws {
        var price = PriceState.assumed(500)
        switch price {
        case .assumed(let value):
            #expect(value == 500)
        default:
            Issue.record("expected assumed")
        }
    }

    @Test func priceState_unknown() async throws {
        var price = PriceState.unknown
        switch price {
        case .unknown:
            break
        default:
            Issue.record("expected unknown")
        }
    }
}
