//  ItemStatus.swift
//  AllMyStuff

import SwiftUI

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case undecided
    case keep
    case sell
    case donate
    case trash

    var id: String { rawValue }

    var label: String {
        switch self {
        case .undecided: "Undecided"
        case .keep: "Keep"
        case .sell: "Sell"
        case .donate: "Donate"
        case .trash: "Trash"
        }
    }

    var color: Color {
        switch self {
        case .undecided: .gray
        case .keep: .green
        case .sell: .orange
        case .donate: .blue
        case .trash: .red
        }
    }
}
