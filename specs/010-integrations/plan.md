# Implementation Plan: Integrations

**Branch**: `010-integrations` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

Integrations are MCP servers registered in Claude Code's **user scope** (`claude mcp add … -s user`), so every Clicky
gets them and Claude Code keeps the sign-in tokens (in its own secure storage). MyClicky wraps the `claude mcp`
commands (`ClaudeMCP`), parses `claude mcp list` for statuses, and ships a JSON catalog. Sign-in uses Claude Code's
OAuth flow for remote servers (research R2). The Apps chip reads the connected list.

## Technical Context

**Language/Version**: Swift 6.4 (Swift 5 mode)

**Primary Dependencies**: Foundation `Process` (claude CLI), SwiftUI

**Storage**: `Resources/integrations.json` (catalog, bundled). No tokens in MyClicky files. Claude Code owns the
connection config and credentials

**Testing**: Checks for catalog decoding, `mcp list` output parsing (connected / needs auth / failed / unknown),
name validation, custom connector validation, search filtering

**Constraints**: Depends on 009 (`ClaudeCodeLocator`). All calls are async with a 20 s timeout

## Constitution Check

| Principle | Check |
|---|---|
| I | ✅ No API spend |
| III | ✅ No MyClicky server; sign-in handled by Claude Code |
| IV | ✅ MyClicky stores no secrets. Custom connectors with header secrets are **not** offered (they'd land in plain config) |
| V | ✅ Integration tools always go through Allow cards (009) unless allowed per Clicky. **Widening**: agents can act in connected apps; listed in the spec edge cases |
| VI | ✅ No OAuth code of our own in v1 (research R2) |
| VII | ✅ Parsers checked |
| VIII | ✅ Ref 10. Deviations listed |

## Project Structure

```text
Resources/integrations.json                        # catalog (copied into the app by build.sh)
Resources/IntegrationIcons/*.png                   # optional brand icons (letter tiles as fallback)
Sources/MyClickyCore/Models/Integration.swift      # catalog entry + custom entry + status
Sources/MyClickyCore/Logic/MCPListParser.swift     # parse `claude mcp list` output
Sources/MyClickyCore/Logic/IntegrationFilter.swift
Sources/MyClicky/Integrations/ClaudeMCP.swift      # add/remove/list/get, sign-in trigger
Sources/MyClicky/Integrations/IntegrationsModel.swift
Sources/MyClicky/Settings/IntegrationsPage.swift  IntegrationRow.swift  CustomConnectorSheet.swift
Sources/MyClicky/Home/Sidebar/AppsChip.swift       # connected icons + "Apps +"
Sources/MyClickyChecks/IntegrationChecks.swift
```
