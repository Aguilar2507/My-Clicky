# Implementation Plan: Agents

**Branch**: `009-agents` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

Replace v0.1's one-shot `AgentRunner` with an `AgentSupervisor` that runs up to 3 Claude Code processes (one per
Clicky run) in `stream-json` mode, parses events with a Core `AgentEventParser`, and writes steps and messages into
the Clicky's chat. Permissions go through Claude Code's permission-prompt tool, served by a tiny bundled MCP bridge
(`MyClickyComputer`). The bridge forwards every tool call over a Unix socket to the app. The app shows Allow cards
and performs computer-use actions (it already holds the Accessibility and Screen Recording permissions). Adds the
Agents page, announcements and daily suggestions.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: Foundation (`Process`, pipes, Unix-domain sockets via `Network.framework` `NWListener`
with `.unix` endpoint), AppKit/CoreGraphics (synthesized clicks/keys), ScreenCaptureKit (agent screenshots)

**Storage**: settings (see data-model.md). Chat gets `agentSessionID`, `alwaysAllowed` rules, run records in messages.
Socket at `~/Library/Application Support/MyClicky/agent.sock` (0600)

**Testing**: Checks for AgentEventParser (every event type, unknown events, partial lines), MCP JSON-RPC framing,
PermissionDescriber (tool call → plain words), RunQueue (limit 3, FIFO), step-cap logic, suggestion JSON parsing,
irreversible-action keyword guard

**Constraints**: never use the API key for agents (strip `ANTHROPIC_API_KEY`, as in v0.1); runs survive the panel closing

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ Subscription only. SC-005 verifies no API spend |
| II | ✅ |
| III | ✅ Local only; the socket isn't reachable from the network |
| IV | ✅ Screenshots for computer use go only to Claude Code; not stored in chats |
| V | ✅ Allow cards, irreversible guard, stop from chat and notch, 30-min limit, step cap. **Widening**: computer use
lets agents click and type. Risk spelled out in spec US3; mitigated by per-instruction approval (default), visible
companion actions, and pause on user input |
| VI | ✅ One justified helper executable (`MyClickyComputer`): Claude Code only talks to MCP servers as separate processes |
| VII | ✅ Checks listed |
| VIII | ✅ Ref 09. Deviations listed |

## Project Structure

```text
Sources/MyClickyCore/Logic/AgentEventParser.swift     # stream-json lines → AgentEvent
Sources/MyClickyCore/Logic/MCPProtocol.swift          # JSON-RPC 2.0 types + newline framing (shared by bridge and app)
Sources/MyClickyCore/Logic/PermissionDescriber.swift  # tool name + input → "Run the command `ls ~/Desktop`"
Sources/MyClickyCore/Logic/RunQueue.swift             # concurrency 3, FIFO, statuses
Sources/MyClickyCore/Logic/SuggestionParser.swift
Sources/MyClickyCore/Models/AgentRun.swift  ApprovalRequest.swift  Suggestion.swift
Sources/MyClickyComputer/main.swift                   # MCP stdio server: tools/list → forwards tools/call to agent.sock
Sources/MyClicky/Agents/AgentSupervisor.swift         # queue, spawn `claude`, stream parse, timeouts, stop
Sources/MyClicky/Agents/ClaudeCodeLocator.swift       # find binary, version, signed-in check
Sources/MyClicky/Agents/AgentBridgeServer.swift       # NWListener on agent.sock; approvals + computer actions
Sources/MyClicky/Agents/ComputerActions.swift         # screenshot/click/type/key/scroll via CGEvent + companion feedback
Sources/MyClicky/Agents/Announcer.swift               # speech + bubble on start/finish (respects quiet)
Sources/MyClicky/Agents/SuggestionScheduler.swift     # daily run, morning notch
Sources/MyClicky/Home/Conversation/AgentStepRow.swift  AllowCard.swift  KeepGoingCard.swift
Sources/MyClicky/Settings/AgentsPage.swift
Sources/MyClicky/Notch/MorningNotchView.swift
Sources/MyClickyChecks/AgentChecks.swift
build.sh                                              # copy MyClickyComputer into Contents/MacOS
```
