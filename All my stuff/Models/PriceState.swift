import Foundation

enum PriceState: Codable, Sendable {
    case unknown
    case confirmed(Double)
    case assumed(Double)
}

extension PriceState {
    var displayValue: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .confirmed(let value), .assumed(let value):
            return String(format: "%.2f", value)
        }
    }

    var isKnown: Bool {
        if case .confirmed = self { return true }
        return false
    }

    var numericValue: Double? {
        switch self {
        case .unknown:
            return nil
        case .confirmed(let v), .assumed(let v):
            return v
        }
    }
}
