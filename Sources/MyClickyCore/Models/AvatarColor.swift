import Foundation

/// Pastel avatar colors for agents (spec 005 data model): blob color + lighter ring.
public enum AvatarColor: String, Codable, CaseIterable, Sendable {
    case peach, sky, butter, lilac, pink, mint, coral, slate

    public var blobHex: UInt32 {
        switch self {
        case .peach: 0xF2B8A8
        case .sky: 0x9CC7E8
        case .butter: 0xF2DC8C
        case .lilac: 0xB9A6E8
        case .pink: 0xEFA9C6
        case .mint: 0xA8DDB5
        case .coral: 0xF29E8E
        case .slate: 0xA9B4C8
        }
    }

    public var ringHex: UInt32 {
        switch self {
        case .peach: 0xF7D9CC
        case .sky: 0xCFE6F7
        case .butter: 0xFAEFC4
        case .lilac: 0xDED4F7
        case .pink: 0xF8D3E2
        case .mint: 0xD4F0DB
        case .coral: 0xF9CFC6
        case .slate: 0xD6DCE7
        }
    }

    /// The first color not already used, cycling when all are taken.
    public static func next(avoiding used: [AvatarColor]) -> AvatarColor {
        allCases.first { !used.contains($0) } ?? allCases[used.count % allCases.count]
    }
}
