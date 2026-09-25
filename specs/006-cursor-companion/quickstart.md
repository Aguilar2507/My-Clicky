# Quickstart: Cursor Companion

1. `swift build`, then `swift run MyClickyChecks` (ScreenTags and motion groups pass).
2. Build and open. A red glowing triangle trails the pointer on both displays. Clicks go through it.
3. Activity Monitor with the mouse still: < 1% CPU.
4. Hold fn and talk: it pulses. Release: it shimmers, then bounces while speaking. The bubble shows the words and fades 3 s after.
5. "Where is the Apple menu?" → it flies there with a label and returns after ~6 s, or earlier if you move onto it.
6. "Circle the search field in Safari" → a circle draws itself and fades after ~8 s.
7. Double-tap ⌃ → "Ask MyClicky…" at the cursor. Type a question and press Return → answer + saved in Talk.
8. Settings → Cursor: pick blue (it changes at once). Dock cursor ON → it's in the notch and no longer follows.
   Pointing still flies out and back.
9. Compare the Cursor page with `references/heyclicky/08-settings-cursor.png`.
10. Pointing accuracy: 10 "where is…" questions on Finder, Safari, System Settings. Record hits (target ≥ 8).
