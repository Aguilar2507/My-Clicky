# Quickstart: Voice Talk

1. `swift build`, then `swift run MyClickyChecks` (SSE, splitter, voice ranking, quiet policy pass).
2. **Latency**: time 10 answers (release ⌃⌥ → first spoken word) with a stopwatch or screen recording. Record the
   median (target ≤ 2.5 s).
3. Ask a 5-sentence question: continuous speech, and the bubble follows it.
4. Interrupt mid-answer with ⌃⌥: it stops at once and listening starts.
5. Ask in Spanish ("Jarvis, ¿qué hay en mi pantalla?") with an English page on screen: the whole answer is in Spanish, in a Spanish voice (spec 020).
6. Settings → Voice: speed chips, voice grid per language, tap to preview, "Get more voices" opens System Settings.
   Compare with ref 04.
7. Settings → Microphone: devices listed. Test microphone bars move. Unplug a selected USB mic → falls back with a note.
   Compare with ref 05.
8. Join a FaceTime call (or open Voice Memos recording to occupy the mic): ask a question → bubble only with 🔇. Click → speaks.
9. Right-click the menu bar icon → Quiet for 1 hour works.
10. Record the Focus/screen-sharing detection results on macOS 27 below.

## Notes

- Focus detection: _(fill in)_
- Screen-sharing detection (Zoom/Teams/Meet/FaceTime): _(fill in)_
