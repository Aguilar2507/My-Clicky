# Agent stream samples

- `stream.documented.jsonl` is written by hand from Claude Code's documented `--output-format stream-json --verbose`
  shape (system/init, assistant text + tool_use, user tool_result, result). It feeds `AgentChecks`.
- `stream.real.jsonl` is a real run (Claude Code 2.1.283, 2026-10-20): `echo hello` through Bash, then "done". Paths
  are scrubbed, the init line is trimmed to the fields we use and thinking text is removed. Also checked in `AgentChecks`.
