//  Location.swift
//  All my stuff

import Foundation
import SwiftData

@Model
final class Location {
    var name: String
    @Relationship(deleteRule: .nullify)
    var items: [Item] = []

    init(name: String) {
        self.name = name
    }
}
