# Contract: Design System API (spec 014)

What every screen uses. Nothing outside `DesignSystem/` defines its own timing, font size, radius, shadow or surface.

## Motion

```swift
Motion.standard / .quick / .bouncy       // SwiftUI Animation, reduce-motion aware
Motion.animation(.standard)              // same, explicit
Motion.withAnimation(.standard) { … }    // wrapper for state changes
AnyTransition.materialize                // scale 0.96 + blur + opacity (opacity only with Reduce Motion)
AnyTransition.slide(forward: Bool)       // push along x in the direction of travel
AnyTransition.grow(from: UnitPoint)      // scale from an anchor (notch top, cursor)
```

## Type

```swift
Text("…").textStyle(.headline)           // font + tracking + line spacing
Theme.IconSize.small / .medium / .large / .hero
```

## Surfaces

```swift
view.glass(.floating | .structural, radius: Theme.Radius.lg)   // navy glass or solid fallback
view.scrollEdgeFade()                                           // top fade for scrolling content
Theme.Shadow.small / .medium / .large                           // .shadowToken(.large)
Theme.Radius.sm 8 / .md 12 / .lg 16 / .xl 22
Theme.Space.xs 4 / .sm 8 / .md 12 / .lg 16 / .xl 24 / .xxl 32
```

## Feedback

```swift
.buttonStyle(.pressable)                 // for card/row buttons (replaces .plain)
view.hoverHighlight(radius:)             // list rows, cards
FeedbackKind.status / .completion / .warning / .error   // .color, .symbol
Haptics.tap(.toggle | .listen | .done)   // no-op when the setting is off or no Force Touch trackpad
```

## Accessibility

```swift
DisplayPrefs.shared.reduceMotion / .reduceTransparency / .increaseContrast / .forceSolid
```

Contrast-aware tokens (`Theme.cardBorder`, `Theme.textSecondary`, `Theme.textTertiary`, `Theme.hairline`) brighten
when Increase Contrast is on.
