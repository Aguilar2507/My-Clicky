# Data Model: Welcome Tour

## New settings

| Field | Type | Default |
|---|---|---|
| tour.version | Int | 1 |
| tour.step | enum Step | `.intro` |
| tour.completed | [Step] | [] |
| tour.finished | Bool | false (true for users upgrading with a working API key + permissions: they aren't forced through it) |

## Step order

`intro → name → permissions → apiKey → claudeCode → handsOn(notch, talk, point, textMode, dictate) → interview → done`

Rules: `permissions` can't be completed with a missing permission, but it can be skipped with a warning. `apiKey`
is completed only after a successful test. Replay starts at `intro` with `completed` kept, so completed steps show ✓.

## InterviewResult

`clickys: [ { name: String, color: AvatarColor, purpose: String } ]` (exactly 3 after parsing/fallback).
