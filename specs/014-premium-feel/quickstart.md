# Quickstart: Premium Feel

## Prerequisites

`swift build`, `swift run MyClickyChecks` (includes the Premium feel checks), then
`./build.sh && open ~/Applications/MyClicky.app`.

## 1. Response (US1)

1. Open the notch. Press and hold any pill button, a sidebar row and a Settings card without releasing: each sinks
   slightly while held. Drag off and release: it springs back and nothing happens.
2. Hover sidebar rows, chat rows and Voice cards: a soft highlight, different from the selected look.

## 2. Motion (US2)

1. Hover the notch and leave halfway through opening: it shrinks back from where it was, no jump.
2. Open a rename or custom connector card: it materializes (scale + blur clears) and leaves the same way.
3. Settings → General → Replay the welcome tour. Continue: steps enter from the right. Back: they leave to the right.
4. Flip a toggle: the knob has a small bounce. Everything else settles without bouncing.

## 3. Glass (US3)

1. Open a bright web page. Double-tap ⌃: the text field is navy glass with the page blurred behind it.
2. Hold ⌃⌥ and ask something: the bubble grows out of the cursor and is navy glass too.
3. Scroll a long Settings page and a long chat: content fades under the top edge, no hard line.

## 4. Type (US4)

Compare page titles, row titles, captions and section labels on Home, Settings, Spending and the tour: one look per
kind; big titles tighter, uppercase labels wider.

## 5. Accessibility (US5)

System Settings → Accessibility → Display, with MyClicky open:

1. **Reduce motion**: repeat section 2. Everything cross-fades in place; the bot stops floating.
2. **Reduce transparency**: repeat section 3. Surfaces are solid navy.
3. **Increase contrast**: borders and gray text get stronger.

## 6. Haptics (US6)

On a Force Touch trackpad: hold ⌃⌥ (one tap as it starts listening, one as it stops), flip a toggle (one tap).
Settings → General → Haptic feedback off: no taps.

## 7. Snapshots

Re-render every screen listed by `.build/debug/MyClicky --snapshot x` into `docs/screens/<screen>.png` and compare
with the previous renders (`git diff` shows which changed). Same layout; solid navy surfaces (snapshots can't draw
blur).
