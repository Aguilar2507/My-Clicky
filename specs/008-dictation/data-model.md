# Data Model: Dictation

## New settings

| Field | Type | Default | Notes |
|---|---|---|---|
| dictationAutoDetect | Bool | true | Also used by push-to-talk |
| dictationLanguage | enum `en` \| `es` | Mac's language if es, else en | Used when auto-detect is off, and as the tie default |
| spanishLocale | String | Mac region if Spanish-speaking, else `es-MX` | es-ES, es-MX, es-US, es-CO, es-CL, es-AR… |
| customWords | [String] | [] | Trimmed, unique (case-insensitive), max 200 |

`speechLocale` (v0.1) migrates to `dictationLanguage` + `spanishLocale`, then is ignored.

## RecognitionResult (Core)

`locale`, `text`, `segmentConfidences: [Float]`.
`LanguagePicker.pick([RecognitionResult], default:) -> RecognitionResult`.
