import Foundation
import Security

/// Stores the Anthropic API key in the macOS Keychain (never in a file).
enum Keychain {
    private static let service = "com.myclicky.anthropic"
    private static let account = "api-key"

    /// Snapshots (developer tool) never read the real key, so rendered screens can't leak it.
    nonisolated(unsafe) static var snapshotMode = false

    /// Read once per launch: every Keychain read can bring up macOS's "MyClicky wants to use…" prompt.
    nonisolated(unsafe) private static var cached: String?
    private static let resavedKey = "keychainItemOwnedByBuild"

    /// This build's fingerprint (the executable's date). Apps without an Apple team ID are trusted per build, so each
    /// new build asks once; saving the key again from it keeps later launches of the same build from asking.
    private static var buildStamp: String {
        let path = Bundle.main.executablePath ?? ""
        let date = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? nil
        return "\(date?.timeIntervalSince1970 ?? 0)"
    }

    static func apiKey() -> String? {
        if snapshotMode { return "sk-ant-demo-0000000000000000000000000000EXMP" }
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty {
            return env
        }
        if let cached { return cached }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let key = String(data: data, encoding: .utf8) else { return nil }
        cached = key
        // The item trusts the build that saved it. Saving it again from this build means its next launches don't ask.
        if UserDefaults.standard.string(forKey: resavedKey) != buildStamp, setAPIKey(key) {
            UserDefaults.standard.set(buildStamp, forKey: resavedKey)
        }
        return key
    }

    /// Saves the key; the new item is written before the old one is removed, so a failure never loses the key.
    @discardableResult
    static func setAPIKey(_ key: String) -> Bool {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        let staging = "\(account).new"
        var add = base
        add[kSecAttrAccount as String] = staging
        add[kSecValueData as String] = Data(key.utf8)
        SecItemDelete(base.merging([kSecAttrAccount as String: staging]) { $1 } as CFDictionary)
        guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { return false }
        SecItemDelete(base.merging([kSecAttrAccount as String: account]) { $1 } as CFDictionary)
        let rename = SecItemUpdate(base.merging([kSecAttrAccount as String: staging]) { $1 } as CFDictionary,
                                   [kSecAttrAccount as String: account] as CFDictionary)
        guard rename == errSecSuccess else { return false }
        cached = key
        return true
    }
}
