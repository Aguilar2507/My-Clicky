import CoreGraphics
import MyClickyCore

/// Checks for spec 006 (cursor companion): screen tags, motion, layout and coordinate mapping.
enum CompanionChecks {
    static func run() {
        Check.group("Screen tags: drawings") {
            let reply = "Here it is. [POINT:10,20:Search:screen 1][DRAW:circle:100,200,30][DRAW:arrow:1,2,3,4:screen 2]"
                + "[DRAW:box:5,6,70,80][DRAW:underline:1,50,90]"
            let parsed = ScreenTags.parse(reply)
            Check.equal(parsed.text, "Here it is.")
            Check.equal(parsed.point, .point(x: 10, y: 20, label: "Search", screen: 1))
            Check.equal(parsed.drawings, [.circle(x: 100, y: 200, r: 30, screen: 1),
                                          .arrow(x1: 1, y1: 2, x2: 3, y2: 4, screen: 2),
                                          .box(x: 5, y: 6, w: 70, h: 80, screen: 1)], "max 3 drawings")
            Check.equal(ScreenTags.parse("x [DRAW:circle:1,2]").drawings, [], "wrong value count dropped")
            Check.equal(ScreenTags.parse("x [draw: Box : 1, 2, 3, 4 : screen 3]").drawings,
                        [.box(x: 1, y: 2, w: 3, h: 4, screen: 3)], "case and spaces tolerated")
            Check.equal(ScreenTags.parse("See [the docs] here").text, "See [the docs] here", "normal brackets kept")
        }

        Check.group("Screen tags: streaming-safe text") {
            Check.equal(ScreenTags.visibleText(partial: "Click Export. [POI"), "Click Export. ")
            Check.equal(ScreenTags.visibleText(partial: "Click Export. [DRAW:circle:12,4"), "Click Export. ")
            Check.equal(ScreenTags.visibleText(partial: "Look [POINT:1,2:x] and"), "Look  and")
            Check.equal(ScreenTags.visibleText(partial: "An array [1, 2"), "An array [1, 2", "not a tag prefix")
            Check.equal(ScreenTags.visibleText(partial: "Open ["), "Open ", "a bare [ could start a tag")
        }

        Check.group("Companion motion") {
            var spring = CompanionSpring(position: .zero)
            let target = CGPoint(x: 300, y: -120)
            for _ in 0..<60 { spring.step(toward: target, dt: 1.0 / 60) }
            Check.expect(spring.isSettled(at: target), "settles within 1 s")
            var jump = CompanionSpring(position: .zero)
            for _ in 0..<5 { jump.step(toward: CGPoint(x: 1000, y: 0), dt: 1.0 / 30) }
            Check.expect(jump.position.x <= 1000 && jump.position.x > 0, "no overshoot at 30 fps")
            var hitch = CompanionSpring(position: .zero)
            hitch.step(toward: CGPoint(x: 1000, y: 0), dt: 5) // a 5 s hitch is clamped and stays stable
            Check.expect(hitch.position.x <= 1000 && hitch.position.x > 0, "stable after a long frame")
        }

        Check.group("Companion layout") {
            let screen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
            let size = CGSize(width: 22, height: 22)
            let normal = CompanionLayout.anchor(mouse: CGPoint(x: 500, y: 500), screen: screen, size: size)
            Check.expect(normal.x > 500 && normal.y < 500, "lower-right of the pointer")
            let right = CompanionLayout.anchor(mouse: CGPoint(x: 1720, y: 500), screen: screen, size: size)
            Check.expect(right.x < 1720, "flips left at the right edge")
            let bottom = CompanionLayout.anchor(mouse: CGPoint(x: 500, y: 5), screen: screen, size: size)
            Check.expect(bottom.y > 5 && bottom.y - 11 >= 0, "flips up at the bottom edge")
            let bubble = CompanionLayout.bubbleOrigin(companion: CGPoint(x: 1700, y: 20), bubble: CGSize(width: 300, height: 60),
                                                      screen: screen)
            Check.expect(bubble.x + 300 <= 1728 - 8 && bubble.y >= 8, "bubble stays on screen")
            let control = CompanionLayout.arcControl(from: .zero, to: CGPoint(x: 1000, y: 0))
            Check.equal(control, CGPoint(x: 500, y: 300), "arc raised by 30% of the distance")
            Check.near(CompanionLayout.flightDuration(from: .zero, to: CGPoint(x: 100, y: 0)), 0.5)
        }

        Check.group("Screenshot → screen mapping") {
            let frame = CGRect(x: 1728, y: 0, width: 2560, height: 1440)
            let p = ScreenMapping.globalPoint(x: 640, y: 360, pixelWidth: 1280, pixelHeight: 720, screenFrame: frame)
            Check.equal(p, CGPoint(x: 1728 + 1280, y: 720), "center maps to center")
            let corner = ScreenMapping.globalPoint(x: -50, y: 9999, pixelWidth: 1280, pixelHeight: 720, screenFrame: frame)
            Check.equal(corner, CGPoint(x: 1728, y: 0), "clamped to the screen")
            Check.near(Double(ScreenMapping.length(30, pixelWidth: 1280, screenFrame: frame)), 60)
        }

        Check.group("Router: drawing phrases") {
            Check.expect(Router.wantsPointing("Circle the search field"))
            Check.expect(Router.wantsPointing("subraya el título"))
            Check.expect(!Router.wantsPointing("I drew a picture"), "whole words only")
        }
    }
}
