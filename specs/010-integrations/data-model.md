# Data Model: Integrations

## CatalogEntry (`Resources/integrations.json`)

| Field | Type | Notes |
|---|---|---|
| id | String | lowercase, `[a-z0-9-]`, used as the Claude Code server name `myclicky-<id>` |
| name | String | Display name |
| description | String | Row text (≤ 2 lines) |
| transport | `http` \| `sse` \| `stdio` | |
| url | String? | For http/sse |
| command | [String]? | For stdio |
| icon | String | Bundled file name or `letter:G` |

## CustomEntry

Same fields with `isCustom = true`. Stored in settings `customIntegrations: [CustomEntry]` (no secrets).

## ConnectionStatus

`connected` · `needsAuth` (shown as "Reconnect required") · `failed(message)` · `checking` · `notAdded`

Derived from `claude mcp list` lines for names starting with `myclicky-`. Servers the user added outside MyClicky are
shown read-only under CONNECTED, with "Managed in Claude Code".
