# Data Model: Agents

## New settings

| Field | Type | Default |
|---|---|---|
| agentWorkingDirectory | String | `~/MyClickyAgent` (exists, "MyClicky default") |
| autoApproveExtraUsage | Bool | false |
| alwaysAllowComputerUse | Bool | false |
| suggestAgentTasks | Bool | true |
| announceStartFinish | Bool | true |
| showUpdatesBesideCursor | Bool | true |
| lastSuggestionsAt | Date? | nil |
| lastSuggestions | [Suggestion] | [] (cleared at the end of the day) |

`agentAllowedTools` (v0.1) is replaced by the safe list in research R2. The old value is ignored.

## Chat additions (Clicky)

| Field | Type | Notes |
|---|---|---|
| agentSessionID | String? | From `system/init` / `result` |
| alwaysAllowed | [String] | Rule strings, e.g. `Bash(ls:*)`, `computer` |
| folderName | String | Slug of the title, stable after creation |

## Message additions

`kind`: `text` (default) · `step` (tool name, summary, status) · `approval` (request id, description, decision) ·
`notice` (stopped / timed out / keep going / stalled).

## AgentRun (in memory + summarized in messages)

`id, chatID, instruction, status (queued|running|awaitingApproval|paused|finished|stopped|failed), startedAt,
endedAt, steps: Int, error: String?`

## AgentEvent (Core)

`initialized(sessionID)` · `text(String)` · `toolUse(id, name, input JSON)` · `toolResult(id, isError, summary)` ·
`result(subtype, text, turns, sessionID, isError)` · `unknown`

## Suggestion

`text, clickyTitle?, createdAt`. Stored in `lastSuggestions` until the end of the day.
