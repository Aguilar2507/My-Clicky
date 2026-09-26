import Foundation
import Security

/// Stores the Anthropic API key in the macOS Keychain (never in a file).
enum Keychain {
    private static let service = "com.myclicky.anthropic"
    private static let account = "api-key"

    /// Snapshots (developer tool) never read the real key, so rendered screens can't leak it.
    nonisolated(unsafe) static var snapshotMode = false

    static func apiKey() -> String? {
        if snapshotMode { return "sk-ant-demo-0000000000000000000000000000EXMP" }
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty {
            return env
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func setAPIKey(_ key: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(key.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }
}
