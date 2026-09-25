# Research: Integrations

> Verify every command and URL during T001, once Claude Code is installed. Update this file with the findings.

## R1 Where integrations live

- **Decision**: Register as Claude Code MCP servers at user scope: `claude mcp add --transport http -s user <id> <url>`
  (remote) or `claude mcp add -s user <id> -- <command> <args…>` (local). Remove with `claude mcp remove <id> -s user`.
  Status from `claude mcp list` (✓ Connected / needs authentication / ✗ Failed).
- **Rationale**: All Clickys see them automatically. Claude Code stores the OAuth tokens securely, so MyClicky never
  touches secrets (IV). No server needed (III).
- **Alternative (future)**: MyClicky runs its own MCP OAuth (discovery + dynamic client registration + PKCE via
  `ASWebAuthenticationSession`) and proxies remote servers through `MyClickyComputer` with Keychain tokens. It
  gives a smoother Connect button, but needs ~500 lines of auth code. Revisit if R2's flow is too clunky.

## R2 Signing in (the risky part)

- **Decision**: After `claude mcp add`, if the list shows "needs authentication", MyClicky opens Terminal with a
  one-line script that starts `claude` and runs its `/mcp` authentication for that server. The browser opens for the
  service's sign-in. A sheet in MyClicky says "Finish signing in to GitHub in your browser, then come back". It polls
  `claude mcp list` every 3 s (up to 5 min) and closes on "Connected".
- **Must verify**: whether `claude "/mcp"` (or a newer `claude mcp` subcommand) can trigger the OAuth for one server
  non-interactively. If a direct command exists, use it and skip Terminal.
- **Fallback**: Clear numbered instructions in the sheet (open Terminal, type `claude`, type `/mcp`, choose the server, sign in).

## R3 Catalog (candidates; each verified before shipping)

| id | Name | Remote URL (to verify) | Description (row text) |
|---|---|---|---|
| github | GitHub | `https://api.githubcopilot.com/mcp/` | Search repositories, inspect issues, PRs, commits, releases, and Actions, then create or update repo work with approval. |
| notion | Notion | `https://mcp.notion.com/mcp` | Search Notion pages and databases, read content, then create, update, comment on, or organize pages. |
| linear | Linear | `https://mcp.linear.app/mcp` | Search Linear issues, teams, projects, and cycles, then create or update issues, comments, and projects. |
| atlassian | Jira & Confluence | `https://mcp.atlassian.com/v1/sse` | Search and update Jira issues and Confluence pages. |
| asana | Asana | `https://mcp.asana.com/sse` | Find, create and update Asana tasks and projects. |
| sentry | Sentry | `https://mcp.sentry.dev/mcp` | Look up Sentry issues, errors and releases. |

Google Docs, YouTube and LinkedIn (seen in ref 10) are added only if an official remote server is confirmed during T001.

## R4 Custom connector validation

- **Decision**: URL → must be `https://`, then `claude mcp add` + `claude mcp get <id>`. A local command → must exist
  and be executable. Header/env secrets are not offered in v1 (IV).
