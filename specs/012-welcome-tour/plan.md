# Implementation Plan: Welcome Tour

**Branch**: `012-welcome-tour` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

A `WelcomeWindowController` hosts a SwiftUI step flow driven by a pure `TourFlow` (Core) that knows the step order,
the completion rules and resume. Status providers (permissions, API key, Claude Code) poll every second while visible.
Hands-on steps subscribe to app events (notch expanded, talk answered, pointed, text-mode sent, dictation inserted).
The interview uses Claude Code (`claude -p`, no tools) when ready, else Haiku through `PaidRequestGate`, and creates
Clickys via `ChatStore`.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: SwiftUI, AppKit, existing services (Permissions, Keychain, ClaudeCodeLocator, ChatStore, PaidRequestGate)

**Storage**: settings `tour` = {step, completed: [String], finished: Bool, version: 1}

**Testing**: Checks for TourFlow (order, resume, skip, replay keeps completion ✓, relaunch-needed transitions),
InterviewParser (3 Clickys JSON, dedupe names, fallback starters)

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ < $0.02 per run. Interview prefers the subscription |
| III | ✅ No account sign-in |
| IV | ✅ Key to Keychain; answers not stored beyond Clicky purposes |
| VI | ✅ Flow logic pure in Core |
| VII | ✅ Checks listed |
| VIII | ✅ Replay row wording from ref 03. Deviations listed |

## Project Structure

```text
Sources/MyClickyCore/Logic/TourFlow.swift            # steps, next/back/skip, resume, replay rules
Sources/MyClickyCore/Logic/InterviewParser.swift     # {"clickys":[{"name","color","purpose"}×3]} + fallbacks
Sources/MyClicky/Onboarding/WelcomeWindowController.swift
Sources/MyClicky/Onboarding/WelcomeView.swift        # frame, progress dots, Back/Continue/Skip
Sources/MyClicky/Onboarding/Steps/IntroStep.swift  NameStep.swift  PermissionsStep.swift  APIKeyStep.swift
                                  ClaudeCodeStep.swift  HandsOnStep.swift  InterviewStep.swift  DoneStep.swift
Sources/MyClicky/Onboarding/Relauncher.swift         # relaunch the app and resume
Sources/MyClicky/App/AppEvents.swift                 # lightweight event bus the hands-on steps observe
Sources/MyClicky/Settings/GeneralPage.swift          # WELCOME TOUR row now visible
Sources/MyClickyChecks/TourChecks.swift
```
