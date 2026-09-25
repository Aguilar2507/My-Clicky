# Data Model: Clickys and Chats

## Chat (extends 002)

| Field | Type | Default | Notes |
|---|---|---|---|
| avatarColor | enum AvatarColor | `.sky` | peach, sky, butter, lilac, pink, mint, coral, slate. Talk uses the logo |
| purpose | String | "" | Clicky instructions (from the first message, or the welcome interview in 012) |
| isUnread | Bool | false | Set when an assistant/agent message arrives while the chat isn't visible |
| summarizedThroughID | UUID? | nil | Last message folded into `memorySummary` |
| agentSessionID | String? | nil | Filled by 009 |
| lastAgentUseAt | Date? | nil | For 15-minute continuation |

Invariants: exactly one `kind == .talk` chat. Clicky titles are unique (dedupe suffix " 2", " 3").

## AvatarColor palette (blob / ring)

| Name | Blob | Ring |
|---|---|---|
| peach | `#F2B8A8` | `#F7D9CC` |
| sky | `#9CC7E8` | `#CFE6F7` |
| butter | `#F2DC8C` | `#FAEFC4` |
| lilac | `#B9A6E8` | `#DED4F7` |
| pink | `#EFA9C6` | `#F8D3E2` |
| mint | `#A8DDB5` | `#D4F0DB` |
| coral | `#F29E8E` | `#F9CFC6` |
| slate | `#A9B4C8` | `#D6DCE7` |

## Route (Core)

`.talk(question)` · `.clicky(id, task)` · `.newClicky(task)`

## ContextWindow (Core)

Input: messages, summarizedThroughID. Output: `summary`, `recent` (last 6 exchanges), `toFold` (exchanges beyond
12 not yet summarized).
