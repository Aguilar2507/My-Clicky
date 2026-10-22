# Feature Specification: Wake Words, Agent Bot and Task-Done Alerts

**Feature Branch**: `018-agent-presence` · **Created**: 2026-09-29 · **Status**: Implemented

> **Partly replaced:** the "Clicky" / "Clicky Agent" wake words were replaced by "Jarvis" / "Jarvis agent" in
> [020](../020-jarvis-voice/spec.md). The agent bot and the task-done alerts below are still how the app works.

**Input**: "I want it to recognize some very specific voice commands: 'Clicky' = I'm talking to Clicky only, the
cursor beside mine. 'Clicky Agent' = calls the Code CLI and uses my subscription. Every time I say 'Clicky Agent' or
'Hey Clicky Agent' I want the cursor beside mine to disappear and the bot, the exact same bot from the home page, to
appear from the bottom left corner, pop up beside my cursor, pretend to listen with the same animations (floating, the
eyes), and when I'm done, disappear in that exact same corner, so it looks like I'm talking to an agent that goes to
work in the background. Also, as a rule for the project, alert me every time a task is done: right now I don't know
when it's done."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Say who I'm talking to (Priority: P1)

Holding ⌃⌥, I start with "Clicky…" (or "Hey Clicky…") to talk to the cursor companion: the question goes to Talk
without the wake word. I start with "Clicky Agent…" (or "Hey Clicky Agent…", "Clicky agente…") to give a task to a
Clicky, run by Claude Code on my subscription. The old "agent…" keeps working. Common mishearings ("Clickie",
"Klicky", "Click he") are understood.

**Acceptance**: "Clicky, what's this button?" → Talk asks "what's this button?"; "Hey Clicky Agent, summarize my
Downloads folder" → a Clicky gets "summarize my Downloads folder".

### User Story 2 - The agent shows up to listen (Priority: P1)

As soon as I've said "Clicky Agent" (while still holding ⌃⌥), the cursor companion disappears and the home page's bot
pops out of the bottom-left corner of the screen, lands beside my cursor and listens: floating, blinking, eyes wide,
following my pointer. When I let go it nods, flies back to the same corner and disappears, and the cursor companion
returns. The task runs in the background.

**Acceptance**: say "Clicky Agent…": the bot arrives within ~0.5 s of the words being recognized, stays beside the
cursor while I talk, and leaves to the corner when I release the keys. Reduce Motion: it fades in and out beside the
cursor.

### User Story 3 - I always know when a task is done (Priority: P1) — project rule

Whenever a task ends (finished, failed, paused at its step limit, or stopped unexpectedly), MyClicky tells me: a macOS
notification (clicking it opens that Clicky's chat), a spoken line when it's free to speak (queued, never dropped;
skipped only while quiet), the bubble beside the cursor, a haptic tap and the notch badge.

**Acceptance**: give a task by voice, keep working in another app: when it finishes, a notification appears and
MyClicky says "Build Lab finished. …"; clicking the notification opens the chat.

### Edge Cases

- "Clicky" alone isn't enough to trigger the agent bot; the bot needs "Clicky Agent" (or "agent").
- The bot showed, but the final transcript isn't an agent request (misheard): the bot leaves and Talk answers.
- Quick press released before "Clicky Agent" is recognized: no bot; routing still uses the final transcript.
- Plain "click" is not a wake word for Talk ("click the export button" stays intact).
- Several Clickys finish together: one notification each; spoken lines play one after another.
- Notifications turned off in System Settings: the other alerts still happen.

## Requirements *(mandatory)*

- **FR-001**: Wake words MUST be recognized at the start of the transcript, after an optional greeting (hey, hi, ok,
  okay, oye, hola): "Clicky" → Talk (word removed); "Clicky Agent"/"Clicky agente" → agent task; "agent…" still works.
- **FR-002**: Mishearings of "Clicky" MUST be accepted (clickie, clicki, clickey, cliky, klicky, kliky, cliqui,
  "click he"); "click" alone MUST only count when followed by "agent".
- **FR-003**: The agent bot MUST appear from the live transcript (before release) and hide the cursor companion.
- **FR-004**: The bot MUST enter from and exit to the bottom-left corner of the display with the pointer, and follow
  the pointer while listening. With Reduce Motion it fades in and out in place.
- **FR-005**: After an agent request, the assistant MUST return to idle (fixes announcements waiting forever and the
  next push-to-talk being ignored).
- **FR-006**: Every task end MUST alert: notification (always), speech (queued, unless quiet or turned off in
  Settings → Agents), bubble (per setting), haptic, notch badge.
- **FR-007**: Notification permission is asked once, the first time a task finishes (new permission, justified by
  FR-006; nothing else is sent).

## Success Criteria *(mandatory)*

- **SC-001**: 10 out of 10 "Clicky Agent" requests show the bot and start a Clicky.
- **SC-002**: 100% of task ends produce a notification.
- **SC-003**: No announcement waits more than 60 s for MyClicky to be free.

## Cost impact

None. Wake words and the bot are on-device; the agent still runs on the Claude subscription (Claude Code), not the API.

## Deviations from HeyClicky (Principle VIII)

| HeyClicky | MyClicky | Why |
|---|---|---|
| "agent" prefix only | "Clicky" / "Clicky Agent" wake words | Your choice |
| Agents work silently in the background | The bot visibly takes the task and leaves; every task end is announced | Your choice (project rule) |
