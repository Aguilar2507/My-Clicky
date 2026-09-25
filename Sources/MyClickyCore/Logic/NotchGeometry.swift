import CoreGraphics

/// Where MyClicky's notch shape and app panel go on one display, in AppKit global coordinates (origin bottom-left).
public struct NotchGeometry: Equatable, Sendable {
    public static let wingWidth: CGFloat = 88
    public static let expandedSize = CGSize(width: 990, height: 650)
    public static let pillWidth: CGFloat = 200

    public let screenFrame: CGRect
    public let hasNotch: Bool
    /// The small black shape (notch + wings, or the pill on displays without a notch).
    public let collapsedRect: CGRect
    /// The app panel when opened, attached to the top edge.
    public let expandedRect: CGRect

    /// - Parameters:
    ///   - auxLeftWidth/auxRightWidth: widths of `NSScreen.auxiliaryTopLeftArea/RightArea` (nil = no notch).
    ///   - safeAreaTop: `NSScreen.safeAreaInsets.top` (the notch height).
    ///   - menuBarHeight: used for the pill height on displays without a notch.
    public init(screenFrame: CGRect, auxLeftWidth: CGFloat?, auxRightWidth: CGFloat?,
                safeAreaTop: CGFloat, menuBarHeight: CGFloat) {
        self.screenFrame = screenFrame
        let notchWidth: CGFloat?
        if let left = auxLeftWidth, let right = auxRightWidth, safeAreaTop > 0 {
            let width = screenFrame.width - left - right
            notchWidth = width > 0 ? width : nil
        } else {
            notchWidth = nil
        }
        hasNotch = notchWidth != nil

        let collapsedWidth = min(screenFrame.width, (notchWidth ?? (Self.pillWidth - 2 * Self.wingWidth)) + 2 * Self.wingWidth)
        let collapsedHeight = hasNotch ? safeAreaTop : max(menuBarHeight, 22)
        collapsedRect = CGRect(x: screenFrame.midX - collapsedWidth / 2, y: screenFrame.maxY - collapsedHeight,
                               width: collapsedWidth, height: collapsedHeight)

        let width = min(Self.expandedSize.width, screenFrame.width)
        let height = min(Self.expandedSize.height, screenFrame.height)
        var x = screenFrame.midX - width / 2
        x = max(screenFrame.minX, min(x, screenFrame.maxX - width))
        expandedRect = CGRect(x: x, y: screenFrame.maxY - height, width: width, height: height)
    }

    /// The collapsed rect expressed inside the expanded panel (origin bottom-left of the panel).
    public var collapsedInPanel: CGRect {
        collapsedRect.offsetBy(dx: -expandedRect.minX, dy: -expandedRect.minY)
    }
}
