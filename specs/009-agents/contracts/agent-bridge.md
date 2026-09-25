# Contract: Agent bridge (MyClickyComputer ⇄ app)

## Claude Code → MyClickyComputer (MCP over stdio)

Server name `myclicky`. Tools (all `inputSchema` JSON Schema objects):

| Tool | Input | Result content |
|---|---|---|
| approve | `{tool_name: string, input: object}` | text: `{"behavior":"allow","updatedInput":{…}}` or `{"behavior":"deny","message":"…"}` |
| screenshot | `{screen?: int}` | image (jpeg, base64) + text "Screen N of M, WxH" |
| click | `{x, y, button?: "left"\|"right", count?: 1\|2, screen?: int}` | text "ok" |
| type | `{text: string}` | text "ok" |
| key | `{combo: string}` e.g. "cmd+space", "return" | text "ok" |
| scroll | `{dx: int, dy: int}` | text "ok" |
| move | `{x, y, screen?: int}` | text "ok" |

`--mcp-config` file written by the app to `~/Library/Application Support/MyClicky/mcp.json`:
`{"mcpServers":{"myclicky":{"command":"<app>/Contents/MacOS/MyClickyComputer","args":["--chat","<chatID>"]}}}`
(plus the integrations from 010).

## MyClickyComputer → app (Unix socket `agent.sock`, newline-delimited JSON)

Request: `{"id": "...", "chatID": "...", "tool": "click", "input": {...}}`
Response: `{"id": "...", "ok": true, "content": [{"type":"text","text":"ok"}]}` or `{"id":"...","ok":false,"error":"..."}`

The app validates that `chatID` belongs to a running run. Unknown chat → error. The socket file mode is 0600.

## Clicky system prompt (appended)

v0.1 `Prompts.agent(workingDirectory:)` + "You are {name}, one of the user's Clickys. Your job: {purpose}. Your
folder is {folder}. To see or use the user's screen, use the myclicky tools (screenshot first, then click/type in
screenshot pixel coordinates). Never send, delete, buy, post or change system settings without asking in your
final message first."
