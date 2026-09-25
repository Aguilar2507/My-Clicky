import Foundation

/// v0.1 kept its settings in `config.json`. On first launch of v0.2 its values move into `settings.json`,
/// and the old file is renamed `config.v1.backup.json`. Runs only when settings.json doesn't exist yet.
public enum LegacyConfigMigration {
    public static func run(paths: AppPaths) -> Settings? {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: paths.settings.path),
              let data = JSONFile.read(paths.legacyConfig),
              var settings = try? TolerantDecoder.decode(Settings.self, from: data, defaults: Settings())
        else { return nil }

        settings.version = 1 // config.json had no version; run every upgrade step
        SettingsMigrations.upgrade(&settings)
        do {
            try JSONFile.write(settings, to: paths.settings)
            if fm.fileExists(atPath: paths.legacyBackup.path) { try fm.removeItem(at: paths.legacyBackup) }
            try fm.moveItem(at: paths.legacyConfig, to: paths.legacyBackup)
        } catch {
            return settings // values are still used this launch; the move is retried next time
        }
        return settings
    }
}
