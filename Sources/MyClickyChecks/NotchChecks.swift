import CoreGraphics
import MyClickyCore

/// Checks for spec 003 (notch home): geometry and the open/close state machine.
enum NotchChecks {
    static func run() {
        Check.group("Notch geometry") {
            // 16" MacBook Pro: 1728×1117 points, notch ≈ 184 pt wide, 38 pt tall.
            let built = NotchGeometry(screenFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
                                      auxLeftWidth: 772, auxRightWidth: 772, safeAreaTop: 38, menuBarHeight: 24)
            Check.expect(built.hasNotch)
            Check.equal(built.collapsedRect, CGRect(x: 864 - 184 / 2 - 88, y: 1117 - 38, width: 184 + 176, height: 38))
            Check.equal(built.expandedRect, CGRect(x: 864 - 495, y: 1117 - 650, width: 990, height: 650))
            Check.equal(built.collapsedInPanel.maxY, built.expandedRect.height, "shape sits at the panel's top edge")

            // External 2560×1440 display to the right, no notch → pill.
            let external = NotchGeometry(screenFrame: CGRect(x: 1728, y: 0, width: 2560, height: 1440),
                                         auxLeftWidth: nil, auxRightWidth: nil, safeAreaTop: 0, menuBarHeight: 24)
            Check.expect(!external.hasNotch)
            Check.equal(external.collapsedRect, CGRect(x: 1728 + 1280 - 100, y: 1440 - 24, width: 200, height: 24))
            Check.equal(external.expandedRect.midX, 1728 + 1280)

            // Tiny screen: panel clamped inside it.
            let tiny = NotchGeometry(screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
                                     auxLeftWidth: nil, auxRightWidth: nil, safeAreaTop: 0, menuBarHeight: 24)
            Check.equal(tiny.expandedRect, CGRect(x: 0, y: 0, width: 800, height: 600))
        }

        Check.group("Notch open/close rules") {
            var s = NotchState()
            s.pointer(inShape: true, inPanel: false, now: 0)
            Check.equal(s.phase, .hovering(since: 0))
            s.pointer(inShape: true, inPanel: false, now: 0.1)
            Check.expect(!s.isExpanded, "not yet at 100 ms")
            s.pointer(inShape: true, inPanel: false, now: 0.16)
            Check.expect(s.isExpanded, "opens after resting 150 ms")

            var brush = NotchState()
            brush.pointer(inShape: true, inPanel: false, now: 0)
            brush.pointer(inShape: false, inPanel: false, now: 0.05)
            Check.equal(brush.phase, .collapsed, "brushing past doesn't open")

            s.pointer(inShape: false, inPanel: false, now: 1.0)
            Check.equal(s.phase, .expanded(outsideSince: 1.0))
            s.pointer(inShape: false, inPanel: false, now: 1.3)
            Check.expect(s.isExpanded, "grace period")
            s.pointer(inShape: false, inPanel: true, now: 1.4)
            Check.equal(s.phase, .expanded(outsideSince: nil), "coming back cancels the grace")
            s.pointer(inShape: false, inPanel: false, now: 2.0)
            s.pointer(inShape: false, inPanel: false, now: 2.4, isBusy: true)
            Check.expect(s.isExpanded, "stays open while typing")
            s.pointer(inShape: false, inPanel: false, now: 3.0)
            s.pointer(inShape: false, inPanel: false, now: 3.6)
            Check.equal(s.phase, .collapsed, "closes after 500 ms outside")

            s.open()
            s.outsideClick(isBusy: true)
            Check.expect(s.isExpanded, "outside click ignored while a menu is open")
            s.outsideClick()
            Check.equal(s.phase, .collapsed)
            s.open(); s.escape()
            Check.equal(s.phase, .collapsed, "Esc closes")
            s.open(); s.popOut()
            s.pointer(inShape: true, inPanel: false, now: 10)
            s.pointer(inShape: true, inPanel: false, now: 11)
            Check.equal(s.phase, .poppedOut, "hover doesn't open a second copy")
            s.closeWindow()
            Check.equal(s.phase, .collapsed)
        }
    }
}
