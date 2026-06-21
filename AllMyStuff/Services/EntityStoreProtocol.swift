import Foundation

protocol EntityStoreProtocol: Sendable {
    associatedtype Entity: Identifiable

    var items: [Entity] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func fetchAll() throws
    func query(_ predicate: @escaping @Sendable (Entity) -> Bool) throws -> [Entity]
    func insert(_ entity: Entity) throws
    func save(_ entity: Entity) throws
    func delete(_ entity: Entity) throws
    func refresh() throws
}
