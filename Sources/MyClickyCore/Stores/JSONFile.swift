import Foundation

/// JSON helpers shared by every store: consistent coding, atomic writes, and setting damaged files aside.
public enum JSONFile {
    /// ISO-8601 with milliseconds, so dates round-trip exactly (plain `.iso8601` drops fractions).
    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISODate.string(from: date))
        }
        return encoder
    }

    /// Accepts dates with or without fractional seconds.
    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            guard let date = ISODate.date(from: text) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(text)"))
            }
            return date
        }
        return decoder
    }

    public static func encode<T: Encodable>(_ value: T) throws -> Data { try encoder.encode(value) }

    public static func read(_ url: URL) -> Data? { try? Data(contentsOf: url) }

    /// Writes to a temp file in the same folder, then swaps it in, so a crash never leaves a half-written file.
    public static func write(_ data: Data, to url: URL) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let temp = folder.appendingPathComponent(".\(url.lastPathComponent).tmp")
        try data.write(to: temp)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
        } else {
            try FileManager.default.moveItem(at: temp, to: url)
        }
    }

    public static func write<T: Encodable>(_ value: T, to url: URL) throws {
        try write(encode(value), to: url)
    }

    /// Renames an unreadable file to `<name>.damaged` (never deletes it). Returns the new location.
    @discardableResult
    public static func setAside(_ url: URL) -> URL? {
        var target = url.appendingPathExtension("damaged")
        var n = 2
        while FileManager.default.fileExists(atPath: target.path) {
            target = url.appendingPathExtension("damaged\(n)")
            n += 1
        }
        return (try? FileManager.default.moveItem(at: url, to: target)) != nil ? target : nil
    }
}
