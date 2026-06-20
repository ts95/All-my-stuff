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

    @Relationship(deleteRule: .nullify, inverse: \ItemCategory.items)
    var categories: [ItemCategory] = []

    @Relationship(deleteRule: .nullify, inverse: \ItemLocation.items)
    var locations: [ItemLocation] = []

    init(name: String, datePurchased: Date? = nil) {
        self.name = name
        self.datePurchased = datePurchased
    }
}
