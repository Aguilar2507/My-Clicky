# Contract: On-disk storage

Folder: `~/Library/Application Support/MyClicky/`

| Path | Owner | Format |
|---|---|---|
| `settings.json` | SettingsStore | Settings (data-model.md), pretty-printed, sorted keys |
| `chats/<uuid>.json` | ChatStore | Chat |
| `chats/<uuid>.json.damaged` | ChatStore | Set-aside unreadable chat (never read again) |
| `usage.json` | UsageStore | `{ "YYYY-MM": { "questions": Int, "costUSD": Double } }` |
| `config.v1.backup.json` | migration | Untouched copy of the v0.1 `config.json` |

## Rules

1. Writes go to `.<name>.tmp` in the same folder, followed by an atomic replace. A crash leaves the old file intact.
2. Readers accept missing keys (defaults) and ignore unknown keys.
3. No file contains the API key, integration tokens or image data.
4. Migration runs only when `settings.json` is absent and `config.json` is present. It is idempotent.
