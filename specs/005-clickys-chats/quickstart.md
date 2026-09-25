# Quickstart: Clickys and Chats

1. `swift build`, then `swift run MyClickyChecks` (Chat groups pass).
2. Build and open, then hover the notch. With no chats: the greeting screen matches ref 02 (time of day and name correct).
3. Hold fn and ask "what app am I in?". A Talk row appears on top with the preview. Open it: question + answer +
   "Voice · Looked at N screens".
4. Type a follow-up in Talk: the answer uses context.
5. Click +, type "keep an eye on new AI architect jobs": the Clicky is named within 2 s and gets a color.
6. Say "agent, ask {that name} to also check remote roles": it goes to that Clicky.
7. Rename, change color, delete (confirm) work. Talk offers "Clear history" instead.
8. Search "architect": only matching chats, with the snippet. Search with accents removed works.
9. Memory test (spec US6): "my project is called Orion", 15 other questions, then "what's my project called?" → Orion.
   Check that `chats/<talk-id>.json` has a `memorySummary` and no image data.
10. Leave a Clicky unopened while its reply arrives: the blue dot shows and the notch badge increases. Open it and both clear.
