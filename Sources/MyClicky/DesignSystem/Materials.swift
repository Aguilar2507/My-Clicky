import SwiftUI
import AppKit

/// Glass (spec 014 US3, apple-design skill §12): a translucent material tinted with the surface color (spec 015: light
/// or dark with the Mac), a bright top edge in Dark Mode, and a solid fallback with Reduce Transparency (and in snapshots,
/// which can't draw blur).
enum GlassWeight {
    /// Structural regions (sidebar): darker, heavier, separates.
    case structural
    /// Floating chrome (modals, bubble, text field): lighter, draws attention.
    case floating

    var tintOpacity: Double { self == .structural ? 0.9 : 0.78 }
}

private struct GlassBackground<S: InsettableShape>: ViewModifier {
    let weight: GlassWeight
    let shape: S
    let tint: Color
    var behindWindow = false

    func body(content: Content) -> some View {
        let solid = DisplayPrefs.shared.solidSurfaces
        content
            .background {
                if solid {
                    shape.fill(tint)
                } else {
                    ZStack {
                        if behindWindow {
                            VisualEffectBackground().clipShape(shape)
                        } else {
                            shape.fill(.ultraThinMaterial)
                        }
                        shape.fill(tint.opacity(weight.tintOpacity))
                    }
                }
            }
            .overlay { shape.strokeBorder(Theme.cardBorder, lineWidth: 1) }
            .overlay {
                shape.strokeBorder(LinearGradient(colors: [Theme.overlayColor(light: 0, dark: solid ? 0.06 : 0.14), .clear],
                                                  startPoint: .top, endPoint: .center), lineWidth: 1)
            }
    }
}

extension View {
    /// Glass behind this view. `behindWindow` blurs the desktop and other apps (floating windows);
    /// otherwise it blurs this window's own content (modals, sidebar).
    func glass<S: InsettableShape>(_ weight: GlassWeight, in shape: S, tint: Color = Theme.modal,
                                   behindWindow: Bool = false) -> some View {
        modifier(GlassBackground(weight: weight, shape: shape, tint: tint, behindWindow: behindWindow))
    }

    /// Scrolling content fades out under floating chrome instead of meeting a hard line (skill §12).
    func scrollEdgeFade(top: CGFloat = 18, bottom: CGFloat = 0) -> some View {
        mask {
            VStack(spacing: 0) {
                if top > 0 { LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: top) }
                Rectangle().fill(.black)
                if bottom > 0 {
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: bottom)
                }
            }
        }
    }
}

/// The system's behind-window blur, dark, always active (floating panels never become the key app).
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView { GlassView.make() }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// AppKit side of the same glass, for the text-mode field and the companion bubble.
enum GlassView {
    static func make(cornerRadius: CGFloat = 0) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover // follows Light/Dark like a macOS popover (spec 015)
        view.blendingMode = .behindWindow
        view.state = .active
        if cornerRadius > 0 {
            view.wantsLayer = true
            view.layer?.cornerRadius = cornerRadius
            view.layer?.cornerCurve = .continuous
            view.layer?.masksToBounds = true
        }
        return view
    }

    /// A light veil of the window color over the blur (popover look); opaque with Reduce Transparency.
    static var tint: NSColor {
        NSColor.windowBackgroundColor.withAlphaComponent(DisplayPrefs.shared.solidSurfaces ? 1 : 0.35)
    }

    static var border: NSColor { NSColor(Theme.cardBorder) }

    /// A system color resolved for the app's current Light/Dark appearance, for Core Animation layers (which don't
    /// adapt on their own).
    static func cgColor(_ color: NSColor) -> CGColor {
        var resolved = color.cgColor
        NSApp.effectiveAppearance.performAsCurrentDrawingAppearance { resolved = color.cgColor }
        return resolved
    }
}
