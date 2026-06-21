import Foundation
import SwiftData

@Observable
final class ItemStore: EntityStoreProtocol, @unchecked Sendable {
    var items: [Item] = []
    var isLoading: Bool = false
    var error: Error? = nil

    private let context: ModelContext?

    init(context: ModelContext) {
        self.context = context
    }

    init() {
        self.context = nil
    }

    // MARK: - EntityStoreProtocol

    func fetchAll() throws {
        guard let context else {
            return
        }
        isLoading = true
        error = nil
        do {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\Item.name, order: .forward)]
            )
            items = try context.fetch(descriptor)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func query(_ predicate: @escaping @Sendable (Item) -> Bool) throws -> [Item] {
        guard let context else {
            return items.filter(predicate)
        }
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\Item.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        return results.filter(predicate)
    }

    func insert(_ entity: Item) throws {
        guard let context else {
            items.append(entity)
            return
        }
        context.insert(entity)
        try fetchAll()
    }

    func save(_ entity: Item) throws {
        guard let context else {
            return
        }
        try context.save()
        try fetchAll()
    }

    func delete(_ entity: Item) throws {
        guard let context else {
            items.removeAll { $0.id == entity.id }
            return
        }
        context.delete(entity)
        try context.save()
        try fetchAll()
    }

    func refresh() throws {
        try fetchAll()
    }

    // MARK: - Grouping

    func grouped(by keyPath: KeyPath<Item, [ItemCategory]?>) -> [(group: ItemCategory, items: [Item])] {
        var categoryItems: [ItemCategory: [Item]] = [:]
        for item in items {
            if let categories = item[keyPath: keyPath] {
                for category in categories {
                    categoryItems[category, default: []].append(item)
                }
            }
        }
        return categoryItems.map { (group: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group.name < $1.group.name }
    }

    func groupedByLocation() -> [(group: ItemLocation, items: [Item])] {
        var locationItems: [ItemLocation: [Item]] = [:]
        for item in items {
            if let locations = item.locations {
                for location in locations {
                    locationItems[location, default: []].append(item)
                }
            }
        }
        return locationItems.map { (group: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group.name < $1.group.name }
    }

    // MARK: - Factory Methods

    static func live(context: ModelContext) -> ItemStore {
        ItemStore(context: context)
    }

    static func preview() -> ItemStore {
        let store = ItemStore()
        let laptop = Item(name: "Laptop", datePurchased: Date())
        laptop.notes = "2024 MacBook Pro"
        laptop.purchasePrice = 1999.99
        laptop.estimatedValue = 1500

        let headphones = Item(name: "Headphones", datePurchased: Date())
        headphones.notes = "Wireless noise-cancelling"
        headphones.purchasePrice = 349.99

        let phone = Item(name: "Phone", datePurchased: Date())
        phone.notes = "Latest model"
        phone.purchasePrice = 999.99

        let electronics = ItemCategory(name: "Electronics")
        let personal = ItemCategory(name: "Personal")
        let desk = ItemLocation(name: "Desk")
        let bag = ItemLocation(name: "Bag")

        laptop.categories = [electronics]
        laptop.locations = [desk]
        headphones.categories = [electronics, personal]
        headphones.locations = [bag]
        phone.categories = [personal]
        phone.locations = [desk, bag]

        store.items = [laptop, headphones, phone]
        return store
    }

    static func test() -> ItemStore {
        ItemStore()
    }
}
