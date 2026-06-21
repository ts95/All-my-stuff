import Foundation

enum PriceState: Sendable {
    case unknown
    case confirmed(Double)
    case assumed(Double)
}

extension PriceState: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .unknown:
            try container.encode("unknown", forKey: .kind)
        case .confirmed(let value):
            try container.encode("confirmed", forKey: .kind)
            try container.encode(value, forKey: .value)
        case .assumed(let value):
            try container.encode("assumed", forKey: .kind)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        let value = try container.decodeIfPresent(Double.self, forKey: .value)

        switch kind {
        case "confirmed":
            self = .confirmed(value ?? 0)
        case "assumed":
            self = .assumed(value ?? 0)
        default:
            self = .unknown
        }
    }
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
