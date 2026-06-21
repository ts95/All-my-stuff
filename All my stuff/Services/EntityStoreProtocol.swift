import Foundation

protocol EntityStoreProtocol: Sendable {
    associatedtype Entity: Identifiable

    var items: [Entity] { get }
    var isLoading: Bool { get }
    var error: Error? { get }

    func fetchAll() async throws
    func query(_ predicate: @escaping @Sendable (Entity) -> Bool) async throws -> [Entity]
    func insert(_ entity: Entity) async throws
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func refresh() async throws
}
