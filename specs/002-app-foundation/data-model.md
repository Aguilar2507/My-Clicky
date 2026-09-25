# Data Model: App Foundation

All models live in `MyClickyCore`, are `Codable`, and decode tolerantly (a missing key means the default).

## Settings (`settings.json`)

| Field | Type | Default | Notes |
|---|---|---|---|
| version | Int | 2 | Schema version (v0.1 `config.json` = 1) |
| fastModel | String | `claude-haiku-4-5` | |
| pointingModel | String | `claude-sonnet-5` | |
| speechLocale | String | `""` | Replaced by dictation languages in 008 |
| voiceIdentifier | String | `""` | |
| speechRate | Float | 0.52 | Replaced by a speed multiplier in 007 |
| maxHistoryTurns | Int | 10 | |
| claudePath | String | `""` | |
| agentWorkingDirectory | String | `~/MyClickyAgent` | |
| agentAllowedTools | [String] | Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Bash | |

Later features add fields. Each spec lists its own, and every new field has a default.

## Chat (`chats/<id>.json`)

| Field | Type | Notes |
|---|---|---|
| id | UUID | Also the file name |
| kind | enum `talk` \| `clicky` | Exactly one `talk` chat exists (created on demand) |
| title | String | "Talk" or the Clicky's name |
| createdAt, updatedAt | Date | ISO-8601 |
| messages | [Message] | Oldest first |
| memorySummary | String | Empty until 005 fills it |

## Message

| Field | Type | Notes |
|---|---|---|
| id | UUID | |
| role | enum `user` \| `assistant` \| `system` | |
| text | String | Spoken or typed text, without POINT/DRAW tags |
| createdAt | Date | |
| via | enum `voice` \| `typed` \| `agent` | |
| screensSeen | Int | 0 if no screenshot was sent. Images are never stored |

## UsageMonth (`usage.json`: `{ "2026-09": {questions, costUSD} }`)

Unchanged from v0.1 (`UsageLog.Month`), moved to Core.

## Validation rules

- A `Chat` file whose `id` doesn't match its file name is treated as damaged.
- Message `text` is trimmed and never empty for `user` or `assistant` messages.
