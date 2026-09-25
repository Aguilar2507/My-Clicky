import Foundation

/// Loads and saves `settings.json`. Saves are debounced (300 ms) and atomic; `flush()` writes immediately.
public final class SettingsStore: @unchecked Sendable {
    public let paths: AppPaths
    private let queue = DispatchQueue(label: "MyClicky.SettingsStore")
    private var pending: DispatchWorkItem?
    private let debounce: TimeInterval

    public init(paths: AppPaths = .standard, debounce: TimeInterval = 0.3) {
        self.paths = paths
        self.debounce = debounce
    }

    /// settings.json → else a one-time v0.1 config.json migration → else defaults. Damaged files are set aside.
    public func load() -> Settings {
        if let data = JSONFile.read(paths.settings) {
            if var settings = try? TolerantDecoder.decode(Settings.self, from: data, defaults: Settings()) {
                let before = settings.version
                SettingsMigrations.upgrade(&settings)
                if before != settings.version { saveNow(settings) }
                return settings
            }
            JSONFile.setAside(paths.settings)
        }
        if let migrated = LegacyConfigMigration.run(paths: paths) { return migrated }
        return Settings()
    }

    public func save(_ settings: Settings) {
        queue.sync {
            pending?.cancel()
            let work = DispatchWorkItem { [paths] in try? JSONFile.write(settings, to: paths.settings) }
            pending = work
            queue.asyncAfter(deadline: .now() + debounce, execute: work)
        }
    }

    public func saveNow(_ settings: Settings) {
        queue.sync {
            pending?.cancel()
            pending = nil
            try? JSONFile.write(settings, to: paths.settings)
        }
    }

    /// Writes any pending save right now (call on quit).
    public func flush() {
        queue.sync {
            guard let work = pending, !work.isCancelled else { return }
            work.perform()
            work.cancel()
            pending = nil
        }
    }
}
