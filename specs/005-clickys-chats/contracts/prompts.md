# Contract: Prompts (Haiku, non-streaming, max_tokens 300)

## Summarize

System: "You maintain a short memory of a conversation between a user and their Mac assistant. Merge the existing
memory with the new exchanges. Keep facts, names, preferences, decisions and open tasks. Drop small talk. At most
120 words, plain text, same language as the user."

User: `Existing memory:\n{summary or "(none)"}\n\nNew exchanges:\n{User: …\nAssistant: …}`

Output: plain text memory (stored as-is, trimmed).

## Name a Clicky

System: "Name a helper based on its job. Reply with JSON only: {\"name\": 1-3 words, Title Case, playful but clear,
like \"Research Buddy\" or \"Signal Radar\"; \"color\": one of peach, sky, butter, lilac, pink, mint, coral, slate}."

User: the Clicky's first instruction.

Output: JSON parsed by `NamingParser`. Invalid → fallback "New Clicky N", color = next unused.

## Talk request context (changes to the v0.1 request)

System prompt (v0.1 `Prompts.assistant`) + `\n\nWhat you remember about this user and conversation:\n{summary}` when
a summary exists. Messages = the last 6 exchanges (text), then the new user turn with screenshots.
