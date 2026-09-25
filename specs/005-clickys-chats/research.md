# Research: Clickys and Chats

## R1 Layout

- **Decision**: A custom `HStack` (sidebar fixed 270 pt + detail) instead of `NavigationSplitView`.
- **Rationale**: The stock split view adds a toolbar, collapse button and material backgrounds that don't match
  `02-app-home.png`. It also misbehaves inside a borderless non-activating panel.

## R2 Long chats

- **Decision**: `ScrollView` + `LazyVStack` of the newest 50 messages, loading 50 more when the top sentinel appears.
  `ScrollViewReader` scrolls to the bottom on open.
- **Rationale**: Meets SC for 500+ messages without a database.

## R3 Memory summaries

- **Decision**: Keep `summarizedThroughID`. When the unsummarized exchanges exceed 12, send the old summary plus the
  exchanges to fold (all but the newest 6) to Haiku with the prompt in `contracts/prompts.md`, and store the ≤ 120-word
  result. Runs in the background after an answer is spoken, never before one.
- **Rationale**: Matches HeyClicky's "basic text summaries". Cost is in the spec. Never delays answers.
- **Alternatives**: Sending the full history (cost grows forever); embeddings/RAG (overkill, needs another service).

## R4 Naming Clickys

- **Decision**: Haiku with a strict prompt returning `{"name": "...", "color": "peach|sky|butter|lilac|pink|mint|coral|slate"}`.
  Parse with `NamingParser`. On failure, "New Clicky N".
- **Rationale**: Creative names like the references ("Signal Radar", "Role Scout") at ~$0.0002 each.

## R5 Routing

- **Decision**: `ChatRouter.route(text, clickys, lastAgentUse, now)`:
  1. No agent prefix → `.talk(question)`.
  2. Agent prefix, and the rest starts with "ask <Name> to" / "tell <Name> to" / "<Name>," where Name matches a
     Clicky title (folded) → `.clicky(id, task)`.
  3. Else, the last used Clicky within 15 min → `.clicky(id, task)`.
  4. Else → `.newClicky(task)`.
- **Rationale**: Extends the baseline's 15-minute follow-up to many Clickys.

## R6 Search folding

- **Decision**: `String.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)`, precomputed per
  chat when saved. Snippet = ±40 characters around the first hit.
