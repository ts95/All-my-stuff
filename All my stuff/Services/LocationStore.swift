import Foundation
import SwiftData

@Observable
final class LocationStore: EntityStoreProtocol, @unchecked Sendable {
    var items: [ItemLocation] = []
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
            let descriptor = FetchDescriptor<ItemLocation>(
                sortBy: [SortDescriptor(\ItemLocation.name, order: .forward)]
            )
            items = try context.fetch(descriptor)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func query(_ predicate: @escaping @Sendable (ItemLocation) -> Bool) throws -> [ItemLocation] {
        guard let context else {
            return items.filter(predicate)
        }
        let descriptor = FetchDescriptor<ItemLocation>(
            sortBy: [SortDescriptor(\ItemLocation.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        return results.filter(predicate)
    }

    func insert(_ entity: ItemLocation) throws {
        guard let context else {
            items.append(entity)
            return
        }
        context.insert(entity)
        try fetchAll()
    }

    func save(_ entity: ItemLocation) throws {
        guard let context else {
            return
        }
        try context.save()
        try fetchAll()
    }

    func delete(_ entity: ItemLocation) throws {
        guard let context else {
            items.removeAll { $0 === entity }
            return
        }
        context.delete(entity)
        try context.save()
        try fetchAll()
    }

    func refresh() throws {
        try fetchAll()
    }

    // MARK: - Factory Methods

    static func live(context: ModelContext) -> LocationStore {
        LocationStore(context: context)
    }

    static func preview() -> LocationStore {
        let store = LocationStore()
        store.items = [
            ItemLocation(name: "Desk"),
            ItemLocation(name: "Bag"),
            ItemLocation(name: "Shelf")
        ]
        return store
    }

    static func test() -> LocationStore {
        LocationStore()
    }
}
