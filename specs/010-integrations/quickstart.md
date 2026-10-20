# Quickstart: Integrations

Prerequisite: 009 quickstart passes (Claude Code ready).

1. `swift build`, then `swift run MyClickyChecks` (integration groups pass).
2. Settings → Integrations: compare with ref 10.
3. Connect GitHub → Terminal runs `claude mcp login myclicky-github` and the browser opens → sign in → "● Connected" ≤ 5 s after returning. `claude mcp list` in Terminal shows `myclicky-github`.
4. In an agent: "list my open pull requests" → Allow card → answer from GitHub.
5. Repeat for any other service you have an account for (time each: < 2 min).
6. Revoke GitHub access on github.com → reopen the page → "Reconnect required" → Reconnect works.
7. Disconnect → back to AVAILABLE. `claude mcp list` no longer shows it.
8. Add custom connector with an invalid URL → error. With a valid public MCP URL → added with status.
9. The sidebar Apps chip shows the connected icons and opens the page.
