# Research: Premium Feel

Translating the apple-design skill (written for the web) into native macOS.

## R1. Springs

- **Decision**: SwiftUI `.spring(response:dampingFraction:)`, which takes the same two parameters as the skill (Apple's
  response + damping ratio). Standard 0.35/1.0, quick 0.2/1.0, bouncy 0.35/0.8. Core Animation layers (companion
  bubble) use `CASpringAnimation` with mass 1, `stiffness = (2π/response)²`, `damping = 4π·ratio/response`.
- **Rationale**: SwiftUI springs retarget from the presentation value and carry velocity, which is exactly the
  skill's interruptibility rule (§3) for free. Bounce only on toggles and gesture-driven motion (§4).
- **Alternatives**: `.snappy`/`.smooth` presets (less explicit, can't be checked against the skill's table); timing
  curves (not interruptible without jumps).

## R2. Reduce Motion / Transparency / Increase Contrast

- **Decision**: one `@Observable DisplayPrefs` reading `NSWorkspace.shared.accessibilityDisplayShould…` and updating
  on `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`. Theme tokens that depend on it are computed
  properties, so Observation re-renders any view that read them.
- **Rationale**: works for SwiftUI and for AppKit/Core Animation code (bubble, text field) alike; the SwiftUI
  environment values only reach views.
- **Alternatives**: `@Environment(\.accessibilityReduceMotion)` in every view (touches dozens of files, misses AppKit).

## R3. Materials

- **Decision**: `NSVisualEffectView` (`.hudWindow` material, `.behindWindow` blending, dark appearance, `.active`)
  under a navy tint (Midnight at 55–75 % depending on weight) and a 1 pt top-edge gradient highlight.
  Two weights: `structural` (sidebar, heavier tint) and `floating` (bubble, text field, modal, notch).
  Modal cards sit inside the panel, so they use SwiftUI `.ultraThinMaterial` (within-window blur of the panel).
- **Rationale**: the tint keeps spec 013's navy; the system material gives real blur plus its own Reduce Transparency
  handling. We override that handling with our own solid navy so it doesn't turn gray.
- **Snapshots**: `layer.render(in:)` can't capture `NSVisualEffectView`, so `DisplayPrefs.forceSolid` is set in
  snapshot mode; renders show the solid navy fallback.

## R4. Companion bubble blur

- **Decision**: host the bubble in its own `NSVisualEffectView` subview whose frame follows the bubble each frame;
  the overlay's other layers move into full-size host views ordered drawings → bubble → label → companion.
- **Rationale**: a `CALayer` can't blur what's behind its window; `backgroundFilters` don't sample other windows.
- **Alternatives**: no blur, just a deeper tint (simpler, but fails FR-008).

## R5. Press and hover feedback

- **Decision**: in `ButtonStyle`s, `configuration.isPressed` → `scaleEffect(0.97)` + `brightness(±0.06)` with
  `Motion.quick`. SwiftUI buttons report pressed on mouse-down and un-press when dragged outside, which matches the
  skill's tap rules (§10). Hover via `.onHover` + a `Box<Bool>`, drawn as a 6 % white fill.
- **Alternatives**: `simultaneousGesture(DragGesture(minimumDistance: 0))` (fires actions wrongly on drag-off).

## R6. Typography

- **Decision**: keep today's sizes (layout parity) but name them; SF's automatic optical sizing and tracking tables
  stay on, and we add a small size-specific adjustment: 26–28 pt −0.5, 20–22 pt −0.3, 17 pt −0.1, 12–15 pt 0,
  11 pt +0.1, uppercase labels +1.2. Line spacing: titles 0, body 2, captions 1.
- **Mapping for odd sizes**: 10/11 → caption2, 16 → callout or body by context, 18/19 → title3, 21/24 → title2,
  30+ are hero numerals or icons (kept as `IconSize`/`display` 34).
- **Icons** keep point sizes but come from `Theme.IconSize` and use the weight of the text next to them.

## R7. Tour direction

- **Decision**: `TourFlow` step order decides forward/back; the view keeps the last index in a `Box` and chooses
  `.push(from: .trailing)` forward, `.push(from: .leading)` back (so going back undoes the forward path, §7).

## R8. Haptics

- **Decision**: `NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)` for
  push-to-talk begin/end and toggles, `.generic` for agent finished, fired in the same call that changes the state.
  No sounds (the skill's utility rule; MyClicky already speaks).

## R9. Exemptions

- Drawing strokes on screen (`DrawingLayer`) keep their ease-out: they draw a path, not a UI transition.
- The mic level meter uses `Motion.quick`: continuous tracking, retargeted every sample (§1 continuous feedback).
- Drag physics (momentum projection, rubber-banding, velocity handoff) are unused: MyClicky has no draggable UI.
- Spacing: page-level paddings match HeyClicky's measured layout and stay as they are; the 4-pt tokens are used by
  design-system components and new code (HeyClicky parity wins over re-gridding).
