# Research: Notch Home

## R1 Finding the notch

- **Decision**: For each `NSScreen`, if `auxiliaryTopLeftArea` and `auxiliaryTopRightArea` are non-nil, the notch is
  the gap between them (x from left.maxX to right.minX), with height `safeAreaInsets.top`. Otherwise the display has
  no notch: use a 200 × menu-bar-height pill (`NSStatusBar.system.thickness`) centered at the top.
- **Rationale**: Public APIs (macOS 12+), no hard-coded models.
- **Alternatives**: Hard-coded notch widths per model (fragile).

## R2 Window level and Spaces

- **Decision**: `NSPanel` with `.borderless` + `.nonactivatingPanel`, level `NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 2)`,
  `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`,
  `hidesOnDeactivate = false`, and `canBecomeKey` returning true only while expanded.
- **Rationale**: This is the level other notch utilities use to draw over the menu bar and on full-screen Spaces.
  Nonactivating keeps the frontmost app active until you interact with the panel.

## R3 Hover detection without blocking clicks

- **Decision**: The panel stays sized to the expanded frame, with `ignoresMouseEvents = true` while collapsed. A
  global + local `.mouseMoved` monitor checks whether the pointer is inside the collapsed shape rect (a few
  comparisons per event). After a 150 ms rest, set `ignoresMouseEvents = false` and expand. While expanded, an
  outside-for-500 ms timer collapses.
- **Rationale**: A tracking area wouldn't fire while mouse events are ignored, and resizing the window on every
  open looks jerky. SwiftUI animates the shape inside a fixed window (Dynamic-Island style).
- **Risk**: Global mouse-moved monitoring requires Accessibility (already granted for hotkeys).

## R4 The grow animation

- **Decision**: One `NotchShape` whose `animatableData` is (width, height, bottomRadius). Collapsed = notch size;
  expanded = 990 × 650. Content fades in after 120 ms. Spring response 0.35, damping 0.85.
- **Rationale**: Matches the "pours out of the notch" look of `02-app-home.png` (black top fading into the window).

## R5 Pop out

- **Decision**: `NSWindow` with `.titled, .closable, .resizable, .fullSizeContentView`, a hidden title and hidden
  traffic lights (HeyClicky shows only the pop-out and ✕ icons), `isMovableByWindowBackground = true`, frame saved
  via `setFrameAutosaveName("MyClickyWindow")`. The same `HomeRoot` view moves between panel and window (FR-006).

## R6 Dock icon

- **Decision**: `NSApp.setActivationPolicy(showInDock ? .regular : .accessory)`, applied at launch and whenever the
  setting changes. `applicationShouldHandleReopen` opens the pop-out window.
- **Note**: `LSUIElement` stays `true` in Info.plist, so the default is no Dock icon from the first frame.
