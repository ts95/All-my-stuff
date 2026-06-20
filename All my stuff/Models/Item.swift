import SwiftData
import Foundation

@Model
final class Item {
    var id: UUID?
    @Attribute(.unique)
    var name: String
    var notes: String = ""
    var photo: Data?
    var purchasePrice: PriceState?
    var estimatedValue: PriceState?
    var datePurchased: Date?

    @Relationship(deleteRule: .nullify, inverse: \Category.items)
    var categories: [Category] = []

    @Relationship(deleteRule: .nullify, inverse: \Location.items)
    var locations: [Location] = []

    init(name: String, datePurchased: Date? = nil) {
        self.name = name
        self.datePurchased = datePurchased
    }
}
