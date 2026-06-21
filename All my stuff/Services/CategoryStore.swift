import Foundation
import SwiftData

@Observable
final class CategoryStore: EntityStoreProtocol, @unchecked Sendable {
    var items: [ItemCategory] = []
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
            let descriptor = FetchDescriptor<ItemCategory>(
                sortBy: [SortDescriptor(\ItemCategory.name, order: .forward)]
            )
            items = try context.fetch(descriptor)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func query(_ predicate: @escaping @Sendable (ItemCategory) -> Bool) throws -> [ItemCategory] {
        guard let context else {
            return items.filter(predicate)
        }
        let descriptor = FetchDescriptor<ItemCategory>(
            sortBy: [SortDescriptor(\ItemCategory.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        return results.filter(predicate)
    }

    func insert(_ entity: ItemCategory) throws {
        guard let context else {
            items.append(entity)
            return
        }
        context.insert(entity)
        try fetchAll()
    }

    func save(_ entity: ItemCategory) throws {
        guard let context else {
            return
        }
        try context.save()
        try fetchAll()
    }

    func delete(_ entity: ItemCategory) throws {
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

    // MARK: - Factory Methods

    static func live(context: ModelContext) -> CategoryStore {
        CategoryStore(context: context)
    }

    static func preview() -> CategoryStore {
        let store = CategoryStore()
        store.items = [
            ItemCategory(name: "Electronics"),
            ItemCategory(name: "Personal"),
            ItemCategory(name: "Clothing")
        ]
        return store
    }

    static func test() -> CategoryStore {
        CategoryStore()
    }
}
