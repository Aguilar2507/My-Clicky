import Foundation

extension KeyedDecodingContainer {
    /// Decodes `key`, or returns `fallback` when it's missing or malformed, so old files keep loading as models grow.
    public func value<T: Decodable>(_ key: Key, default fallback: @autoclosure () -> T) -> T {
        ((try? decodeIfPresent(T.self, forKey: key)) ?? nil) ?? fallback()
    }
}

/// Decodes a top-level object, filling missing keys from a default value and dropping keys whose values don't fit.
public enum TolerantDecoder {
    public struct NotAnObject: Error {}

    public static func decode<T: Codable>(_ type: T.Type, from data: Data, defaults: T) throws -> T {
        guard var file = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw NotAnObject() }
        let base = try JSONSerialization.jsonObject(with: JSONFile.encode(defaults)) as? [String: Any] ?? [:]
        while true {
            let merged = deepMerge(base, file)
            do {
                return try JSONFile.decoder.decode(T.self, from: JSONSerialization.data(withJSONObject: merged))
            } catch let error as DecodingError {
                // Drop the offending top-level key and retry; its default takes over.
                guard let key = topLevelKey(of: error), file.removeValue(forKey: key) != nil else { throw error }
            }
        }
    }

    static func deepMerge(_ base: [String: Any], _ overlay: [String: Any]) -> [String: Any] {
        var result = base
        for (key, value) in overlay {
            if let a = result[key] as? [String: Any], let b = value as? [String: Any] {
                result[key] = deepMerge(a, b)
            } else {
                result[key] = value
            }
        }
        return result
    }

    private static func topLevelKey(of error: DecodingError) -> String? {
        switch error {
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            return context.codingPath.first?.stringValue
        case .keyNotFound(let key, let context):
            return context.codingPath.first?.stringValue ?? key.stringValue
        @unknown default:
            return nil
        }
    }
}
