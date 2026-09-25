# Implementation Plan: Clickys and Chats

**Branch**: `005-clickys-chats` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

Fill `HomeRoot` with a SwiftUI `NavigationSplitView`-like custom two-column layout (custom, because the stock split
view's chrome doesn't match): `Sidebar` + detail (`EmptyStateView` or `ConversationView`). `ChatStore` (002) gains
unread tracking, search, rename, color and delete. A Core `ChatRouter` decides Talk vs Clicky for every request.
A `MemoryManager` folds old exchanges into `memorySummary` using Haiku. `Assistant` (the v0.1 talk flow) now reads
context from the Talk chat and writes answers into it.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: SwiftUI (List/ScrollView, LazyVStack), Foundation

**Storage**: Chat model extended (see data-model.md). Still one JSON file per chat

**Testing**: Checks for ChatRouter, relative time, greeting, search normalization, memory windowing, name dedupe,
naming/summary JSON parsing

**Performance Goals**: list ready < 200 ms (200 chats); search < 150 ms; open 500-message chat < 300 ms (paged, 50 at a time)

**Constraints**: API calls only for summaries and naming (costs in the spec)

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Cost impact documented. Summaries shrink context. Haiku only |
| II | ✅ |
| III | ✅ Local profile |
| IV | ✅ Text-only chat files; no images |
| V | ✅ Clicky messages go to the agent with existing safety prompt |
| VI | ✅ Routing, windowing, time and greeting logic in Core |
| VII | ✅ Checks listed above |
| VIII | ✅ Ref 02 layout. Deviations listed |

## Project Structure

```text
Sources/MyClickyCore/Models/Chat.swift            # + avatarColor, purpose, unread, summarizedThroughID, sessionID
Sources/MyClickyCore/Logic/ChatRouter.swift       # agent prefix, named Clicky, 15-min continuation → Route
Sources/MyClickyCore/Logic/ContextWindow.swift    # which messages to send / to summarize
Sources/MyClickyCore/Logic/RelativeTime.swift     # "12:29 PM" / "Tuesday" / "Sep 3"
Sources/MyClickyCore/Logic/Greeting.swift         # Morning/Afternoon/Evening + name; key hint text
Sources/MyClickyCore/Logic/SearchIndex.swift      # folding (case/diacritics) + snippet
Sources/MyClickyCore/Logic/NamingParser.swift     # parse {"name","color"} JSON; dedupe " 2"
Sources/MyClicky/Home/HomeView.swift              # two-column layout
Sources/MyClicky/Home/Sidebar/SidebarView.swift  ChatRow.swift  SearchField.swift  ProfileFooter.swift  AppsChip.swift
Sources/MyClicky/Home/EmptyStateView.swift        # mascot + pill + greeting
Sources/MyClicky/Home/Conversation/ConversationView.swift  MessageBubble.swift  Composer.swift  ChatHeader.swift
Sources/MyClicky/Home/AboutSheet.swift
Sources/MyClicky/Talk/MemoryManager.swift         # summarize via ClaudeClient (Haiku), non-streaming
Sources/MyClicky/Talk/ClickyNamer.swift           # name + color via Haiku
Sources/MyClicky/Talk/Assistant.swift             # use ChatRouter + ContextWindow; write messages to chats
Sources/MyClickyChecks/ChatChecks.swift
```
