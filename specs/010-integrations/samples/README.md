# `claude mcp list` samples

- `mcp-list.documented.txt` is written by hand in the format Claude Code documents/prints for `claude mcp list`
  (name: target (transport) - status). It feeds `IntegrationChecks`.
- `mcp-list.real.txt` is real output (Claude Code 2.1.283, 2026-10-20): two claude.ai connectors (names with spaces, no
  transport) and `myclicky-sentry`. `✔`/`!` status marks. Checked in `IntegrationChecks`.
- `mcp-roundtrip.real.txt`: a real add → list → get → remove of `myclicky-sentry`.
