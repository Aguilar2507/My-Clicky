# Data Model: Settings Shell

## New settings

| Field | Type | Default |
|---|---|---|
| profileName | String | first word of `NSFullUserName()` ("Jose") |
| showInScreenRecordings | Bool | true |
| shortcuts | [ShortcutBinding] | defaults below |

## ShortcutBinding

| Field | Type | Notes |
|---|---|---|
| action | enum `pushToTalk` \| `textMode` \| `dictate` \| `handsFreeDictation` | Unique |
| chord | KeyChord | `modifiers: Set<Modifier>` (fn, control, option, command, shift), `keyCode: UInt16?` |
| gesture | enum `hold` \| `doubleTap` \| `press` | `press` = combo with a key |

Defaults: pushToTalk = fn/hold · textMode = control/doubleTap · dictate = control+fn/hold ·
handsFreeDictation = control+fn/doubleTap.

Validation: no two bindings may be equal (same chord + gesture). An empty modifier set is only allowed with a keyCode.

## Matcher events (Core)

Input: `flags(Set<Modifier>, t)`, `keyDown(code, t)`, `keyUp(code, t)`, `tick(t)`.
Output: `began(action)`, `ended(action)`, `cancelled(action)`, `triggered(action)`.

## SettingsPage

`general, voice, microphone, dictation, shortcuts, cursor, agents, integrations`. Each has a title, subtitle
(from the references, MyClicky-named), symbol, group (`none`/`myclicky`/`work`) and `isAvailable`.
