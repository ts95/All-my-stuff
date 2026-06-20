//
//  DataModelTests.swift
//  All my stuffTests
//
//  Created by Toni Sucic on 20/06/2026.
//

import Testing
import SwiftData
@testable import All_my_stuff

@Suite("Data Model Tests")
struct DataModelTests {

    private var context: ModelContext! = ModelContext(.inMemory())

    @Test func item_createsWithRequiredFields() async throws {
        let item = Item(name: "Laptop", datePurchased: Date())
        #expect(item.name == "Laptop")
        #expect(item.notes.isEmpty)
        #expect(item.photo == nil)
        #expect(item.purchasePrice == nil)
    }

    @Test func category_createsWithName() async throws {
        let cat = Category(name: "Electronics")
        context.insert(cat)
        #expect(context.count(for: Category.self) == 1)
    }

    @Test func location_createsWithName() async throws {
        let loc = Location(name: "Office Desk")
        context.insert(loc)
        #expect(context.count(for: Location.self) == 1)
    }

    @Test func item_linksToManyCategories() async throws {
        let laptop = Item(name: "Laptop", datePurchased: Date())
        let electronics = Category(name: "Electronics")
        let work = Category(name: "Work")
        laptop.categories.append(electronics)
        laptop.categories.append(work)
        #expect(laptop.categories.count == 2)
    }

    @Test func item_linksToManyLocations() async throws {
        let phone = Item(name: "Phone", datePurchased: Date())
        let office = Location(name: "Office")
        let home = Location(name: "Home")
        phone.locations.append(office)
        phone.locations.append(home)
        #expect(phone.locations.count == 2)
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
