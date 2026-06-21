import SwiftData
import Foundation

@Model
final class Item {
    var id: UUID?
    @Attribute(originalName: "name")
    var name: String = ""
    var notes: String = ""
    @Attribute(.externalStorage) var photo: Data?
    var purchasePrice: Double?
    var estimatedValue: Double?
    var datePurchased: Date?
    var status: String = ItemStatus.undecided.rawValue

    @Relationship(deleteRule: .nullify, inverse: \ItemCategory.items)
    var categories: [ItemCategory]?

    @Relationship(deleteRule: .nullify, inverse: \ItemLocation.items)
    var locations: [ItemLocation]?

    init(name: String, datePurchased: Date? = nil) {
        self.name = name
        self.datePurchased = datePurchased
    }
}
