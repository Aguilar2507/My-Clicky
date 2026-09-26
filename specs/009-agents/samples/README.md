# Agent stream samples

- `stream.documented.jsonl` is written by hand from Claude Code's documented `--output-format stream-json --verbose`
  shape (system/init, assistant text + tool_use, user tool_result, result). It feeds `AgentChecks`.
- **To do (task T001):** once Claude Code is installed and signed in, save a real run here as `stream.real.jsonl`
  (no secrets), and add it to the checks. If the real shape differs, update `AgentEventParser` and research.md R1.
