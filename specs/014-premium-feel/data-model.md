# Data Model: Premium Feel

## Settings (persisted, `settings.json`)

| Field | Type | Default | Notes |
|---|---|---|---|
| `hapticFeedback` | Bool | `true` | Settings → General → Behavior. Missing in older files → default (TolerantDecoder); no version bump. |

## MotionSpec (`MyClickyCore`, not persisted)

| Name | Response (s) | Damping ratio | Use |
|---|---|---|---|
| standard | 0.35 | 1.0 | Panels, modals, steps, selection |
| quick | 0.2 | 1.0 | Press, hover, small controls, meters |
| bouncy | 0.35 | 0.8 | Toggle knob, gesture-driven motion only |
| fade | 0.18 s ease-out | n/a | Replaces all of the above with Reduce Motion |

Rules: damping ≤ 1 and > 0; response 0.15–0.5; only `bouncy` < 1.

## TypeScale (`MyClickyCore`, not persisted)

| Style | Size | Weight | Tracking (pt) | Line spacing |
|---|---|---|---|---|
| display | 34 | bold | −0.6 | 0 |
| largeTitle | 28 | bold | −0.5 | 0 |
| title1 | 26 | bold | −0.5 | 0 |
| title2 | 22 | semibold | −0.3 | 0 |
| title3 | 20 | semibold | −0.3 | 0 |
| headline | 17 | semibold | −0.1 | 1 |
| body | 17 | regular | −0.1 | 2 |
| callout | 15 | regular | 0 | 2 |
| subheadline | 14 | regular | 0 | 1 |
| footnote | 13 | regular | 0 | 1 |
| caption | 12 | regular | 0 | 1 |
| caption2 | 11 | regular | +0.1 | 0 |
| label | 12 | semibold, uppercase | +1.2 | 0 |

Rule: tracking never increases with size (large text is tighter than small).

## TourDirection

`forward` if the new step's index in `TourState.Step.allCases` is greater than the old one's, otherwise `back`.

## DisplayPrefs (runtime, not persisted)

`reduceMotion`, `reduceTransparency`, `increaseContrast` (mirrors of the macOS settings), `forceSolid` (snapshot mode).
