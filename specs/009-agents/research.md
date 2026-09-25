# Research: Agents

> Claude Code isn't installed on this Mac yet. Every CLI detail below MUST be verified with `claude --help` and a
> dry run before implementation (task T001). Adjust this file if the CLI differs.

## R1 Running Claude Code headless with live progress

- **Decision**: `claude -p "<instruction>" --output-format stream-json --verbose --append-system-prompt "<clicky prompt>"
  [--resume <sessionID>] --max-turns <40|150> --mcp-config <file> --permission-prompt-tool mcp__myclicky__approve
  --allowedTools <safe list>`, with cwd = the Clicky's folder and `ANTHROPIC_API_KEY` removed from the environment.
- **Stream events** (one JSON object per line): `system/init` (session_id, tools), `assistant` (content: text,
  tool_use), `user` (tool_result), `result` (subtype success / error_max_turns / error_during_execution, result text,
  num_turns, duration_ms, session_id, is_error). Unknown types are ignored.
- **Rationale**: Gives live steps plus resumable sessions, on the subscription.

## R2 Permissions → Allow cards

- **Decision**: `--permission-prompt-tool mcp__myclicky__approve`. Claude Code calls the tool with `{tool_name, input}`
  and expects a JSON text result `{"behavior":"allow","updatedInput":{…}}` or `{"behavior":"deny","message":"…"}`.
  The bridge forwards it to the app, which shows the Allow card and replies.
- **Safe list** (no prompt): Read, Glob, Grep, WebSearch, WebFetch, plus Write/Edit restricted to the Clicky folder
  (patterns `Write(./**)`, `Edit(./**)`). Everything else (Bash, edits elsewhere, computer tools) asks unless
  "Always allow for this Clicky" (stored per Clicky as rule strings) or the computer-use setting applies.

## R3 Computer use through an MCP bridge

- **Decision**: `MyClickyComputer` (stdio MCP server, JSON-RPC 2.0, newline-delimited) exposes tools `approve`,
  `screenshot`, `click {x,y,button,count}`, `type {text}`, `key {combo}`, `scroll {dx,dy}`, `move {x,y}`. It holds no
  permissions. It forwards each call to the app over `agent.sock`, and the app performs it (CGEvent, SCK) and returns
  the result (screenshots as MCP image content, 1280 px long edge, JPEG).
- **Rationale**: The app already has Accessibility and Screen Recording. A separate binary would need its own macOS
  permission prompts. Coordinates use the same screenshot-pixel system as POINT tags (006 `ScreenMapping`).
- **Safety**: Before each action the companion flies to the target (0.3 s), so actions are visible. A local
  mouse/keyboard event from the user during a run pauses it (US3).

## R4 Irreversible actions

- **Decision**: The agent system prompt (v0.1 `Prompts.agent`, kept) + a guard in `PermissionDescriber` that tags
  Bash commands matching `rm`, `mv … /dev/null`, `osascript … send`, `curl -X POST`, `git push`, `defaults write`,
  `sudo`… as **sensitive**. Sensitive calls always need an Allow card, even with "Always allow for this Clicky".
- **Rationale**: Principle V applies even when "Always allow computer use" is on.

## R5 Suggestions

- **Decision**: Daily `claude -p` with `--max-turns 1 --allowedTools ""` and a prompt containing Clicky names,
  purposes and memory summaries (text only) → JSON `[{"text","clicky"}]` ×3. Trigger: first user activity after 07:00
  local, if the last run is > 20 h ago.

## R6 Concurrency and watchdog

- **Decision**: `RunQueue` limit 3. Each run gets a 30-min timer and a 5-min no-event watchdog → `failed(stalled)`.
  Stop = SIGINT, then SIGTERM after 2 s.
