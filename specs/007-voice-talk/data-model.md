# Data Model: Voice Talk

## New settings (v0.1 values migrate)

| Field | Type | Default | Migration |
|---|---|---|---|
| speechSpeed | Double (0.5, 0.75, 1, 1.25, 1.5) | 1.0 | from `speechRate` (nearest in the rate table) |
| voiceByLanguage | [String: String] | {} | `voiceIdentifier` → its language slot |
| microphoneUID | String | "" (System Default) | — |
| quietOverride | {mode: auto\|on\|off, until: Date?} | auto | — |

## MessageStreamEvent (Core)

`start(inputTokens, cacheRead, cacheWrite)` · `textDelta(String)` · `stop(reason, outputTokens)` · `error(type, message)` · `ping`

## QuietReason (Core)

`call`, `screenSharing`, `focus`. `isQuiet = override == .on || (override == .auto && !reasons.isEmpty)`.
An override expires at `until` (1 hour).
