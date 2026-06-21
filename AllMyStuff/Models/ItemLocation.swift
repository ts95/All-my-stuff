//  ItemLocation.swift
//  AllMyStuff

/// Renamed from `Location` to avoid ambiguity with Cocoa's built-in types in test targets.
import Foundation
import SwiftData

@Model
final class ItemLocation {
    var name: String = ""
    @Relationship(deleteRule: .nullify)
    var items: [Item]?

    init(name: String) {
        self.name = name
    }
}
