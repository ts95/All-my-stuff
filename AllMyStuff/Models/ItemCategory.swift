//  ItemCategory.swift
//  AllMyStuff

/// Renamed from `Category` to avoid ambiguity with Foundation's internal `Category` type in test targets.
import Foundation
import SwiftData

@Model
final class ItemCategory {
    var id: UUID?
    var name: String = ""
    @Relationship(deleteRule: .nullify)
    var items: [Item]?

    init(name: String) {
        self.name = name
    }
}
