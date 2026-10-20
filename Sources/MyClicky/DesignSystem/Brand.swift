import SwiftUI
import AppKit

/// MyClicky's brand art (spec 016): Apple-style glass. Solid, lit, dimensional objects in the sky → blue → indigo
/// family, a light squircle icon tile, soft realistic shadows, no neon. Keeps 013's ideas (a cursor with a smile and
/// "click" dashes; a cursor-shaped bot with ^ ^ eyes and feet) so MyClicky stays recognizable.
enum Brand {
    // 016 palette (Apple system hues).
    static let sky = Color(hex: 0x64D2FF)
    static let blue = Color(hex: 0x0A84FF)
    static let indigo = Color(hex: 0x5E5CE6)
    static let purple = Color(hex: 0xBF5AF2)
    static let deepIndigo = Color(hex: 0x2B2A8C)
    static let blush = Color(hex: 0xFF7AA8)

    // 013 palette, kept for reference.
    static let midnight = Color(hex: 0x080C1C)
    static let deepNavy = Color(hex: 0x11192F)
    static let electricBlue = Color(hex: 0x3B82F6)
    static let cyanGlow = Color(hex: 0x47D7FF)
    static let violet = Color(hex: 0x7C5CFF)
    static let magenta = Color(hex: 0xE35BFF)
    static let warmGlass = Color(hex: 0xFFD2B8)
    static let iceWhite = Color(hex: 0xF7FAFF)
}

// MARK: Shapes

/// A polygon with rounded corners. Points are fractions of the rect (0…1); `radius` is a fraction of its width.
struct RoundedPolygon: Shape {
    var points: [CGPoint]
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let p = points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        let r = radius * rect.width
        var path = Path()
        let n = p.count
        path.move(to: CGPoint(x: (p[n - 1].x + p[0].x) / 2, y: (p[n - 1].y + p[0].y) / 2))
        for i in 0..<n {
            path.addArc(tangent1End: p[i], tangent2End: p[(i + 1) % n], radius: r)
        }
        path.closeSubpath()
        return path
    }
}

/// "^" eye: a rounded chevron.
struct ChevronEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.9))
        return path
    }
}

/// A small smile, open by `open` (0 = closed curve, 1 = open mouth).
struct BotMouth: Shape {
    var open: CGFloat
    var animatableData: CGFloat {
        get { open }
        set { open = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = rect.minY + rect.height * 0.15
        path.move(to: CGPoint(x: rect.minX, y: top))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: top),
                          control: CGPoint(x: rect.midX, y: top + rect.height * (0.9 + open * 1.3)))
        if open > 0.02 {
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: top),
                              control: CGPoint(x: rect.midX, y: top + rect.height * 0.35))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: Glass

/// Colors for a glass solid: lit side, body, shadow side, plus the light bounced back from below.
struct GlassPalette: Equatable {
    var light: Color
    var body: Color
    var deep: Color
    var bounce: Color
    /// A colored rim light on the shadow side (the second light in a studio render).
    var rim: Color

    static let brand = GlassPalette(light: Color(hex: 0xA6EEFF), body: Color(hex: 0x2A84FF), deep: Color(hex: 0x4A30C4),
                                    bounce: Color(hex: 0x7FE0FF), rim: Color(hex: 0xC98BFF))
    static let feet = GlassPalette(light: Color(hex: 0x7FB6FF), body: Color(hex: 0x3F5CF0), deep: Color(hex: 0x2A2296),
                                   bounce: Color(hex: 0x8FD8FF), rim: Color(hex: 0xB07BFF))
    static let white = GlassPalette(light: .white, body: Color(hex: 0xF2F5FA), deep: Color(hex: 0xC3CCDB),
                                    bounce: .white, rim: .white)
}

/// Renders a shape as a lit 3D glass solid (spec 016): gradient body lit from the top-left, a glowing core, shading
/// underneath, a thick rim of light on the lit edge, bounce light on the lower edge, a soft highlight and a crisp
/// specular, and a fine edge. `size` is the frame's side (the frame is square).
/// Equatable, so an animating parent (`LivelyBot`) doesn't rebuild its ~15 layers every frame; the shape is fixed per
/// call site, so it's left out of the comparison.
struct GlassSolid<S: Shape>: View, Equatable {
    static func == (a: GlassSolid, b: GlassSolid) -> Bool {
        a.size == b.size && a.palette == b.palette && a.highlight == b.highlight && a.highlightAngle == b.highlightAngle
    }

    var shape: S
    var size: CGFloat
    var palette: GlassPalette = .brand
    /// Where the broad highlight sits (fractions of the frame).
    var highlight = CGPoint(x: 0.34, y: 0.28)
    var highlightAngle: Double = -32

    var body: some View {
        ZStack {
            shape.fill(LinearGradient(colors: [palette.light, palette.body, palette.body, palette.deep],
                                      startPoint: UnitPoint(x: 0.15, y: 0), endPoint: UnitPoint(x: 0.9, y: 1)))
            // A glowing core: light scattering inside the glass.
            shape.fill(RadialGradient(colors: [palette.light.opacity(0.55), .clear],
                                      center: UnitPoint(x: 0.46, y: 0.42), startRadius: 0, endRadius: size * 0.45))
            // Shading underneath (ambient occlusion).
            shape.fill(LinearGradient(colors: [.clear, palette.deep.opacity(0.7)],
                                      startPoint: UnitPoint(x: 0.5, y: 0.45), endPoint: .bottom))
            // Form shading: light rolls off the left side into shadow on the right, so it reads as round.
            shape.fill(LinearGradient(colors: [.white.opacity(0.16), .clear, .clear, palette.deep.opacity(0.5)],
                                      startPoint: .leading, endPoint: .trailing))
            // Thickness: the edge darkens inside.
            shape.stroke(palette.deep.opacity(0.5), lineWidth: size * 0.09)
                .blur(radius: size * 0.04)
                .mask(shape)
            // Light rolling over the lit edge.
            shape.stroke(Color.white.opacity(0.95), lineWidth: size * 0.07)
                .blur(radius: size * 0.028)
                .mask(shape)
                .mask(LinearGradient(colors: [.white, .clear], startPoint: .topLeading, endPoint: UnitPoint(x: 0.6, y: 0.6)))
            // Colored rim light on the shadow side.
            shape.stroke(palette.rim, lineWidth: size * 0.06)
                .blur(radius: size * 0.024)
                .mask(shape)
                .mask(LinearGradient(colors: [.clear, .white], startPoint: UnitPoint(x: 0.45, y: 0.4), endPoint: .bottomTrailing))
            // Bounce light from the floor on the lower edge.
            shape.stroke(palette.bounce.opacity(0.75), lineWidth: size * 0.045)
                .blur(radius: size * 0.02)
                .mask(shape)
                .mask(LinearGradient(colors: [.clear, .white], startPoint: UnitPoint(x: 0.5, y: 0.62), endPoint: .bottom))
            // Broad soft highlight and a crisp specular.
            Ellipse()
                .fill(RadialGradient(colors: [.white.opacity(0.7), .white.opacity(0)], center: .center,
                                     startRadius: 0, endRadius: size * 0.2))
                .frame(width: size * 0.4, height: size * 0.2)
                .rotationEffect(.degrees(highlightAngle))
                .position(x: size * highlight.x, y: size * highlight.y)
                .mask(shape)
            Ellipse()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.075, height: size * 0.04)
                .rotationEffect(.degrees(highlightAngle))
                .blur(radius: size * 0.004)
                .position(x: size * (highlight.x - 0.07), y: size * (highlight.y - 0.02))
                .mask(shape)
            // Fine edge: bright where lit, darker where shaded.
            shape.stroke(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.15), palette.deep.opacity(0.45)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing),
                         lineWidth: max(0.5, size * 0.008))
        }
        .frame(width: size, height: size)
        .compositingGroup()
    }
}

// MARK: Dashes

/// Three glossy "click" dashes fanning up and to the right.
struct SparkleDashes: View {
    var size: CGFloat
    var angle: Angle = .zero
    /// 0…1 extra spread, for a little "pop" in animations.
    var pop: CGFloat = 0

    var body: some View {
        let dashes: [(Color, Color, CGFloat, CGFloat, Double)] = [
            (Brand.sky, Color(hex: 0x30B0FF), 0.30, 0.18, -55),
            (Color(hex: 0x3D9BFF), Brand.indigo, 0.58, 0.46, -28),
            (Brand.indigo, Brand.purple, 0.70, 0.80, 0),
        ]
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let d = dashes[i]
                let dash = Capsule(style: .continuous)
                ZStack {
                    dash.fill(LinearGradient(colors: [d.0, d.1], startPoint: .leading, endPoint: .trailing))
                    dash.fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center))
                        .padding(size * 0.012)
                    dash.stroke(Color.white.opacity(0.5), lineWidth: max(0.5, size * 0.008))
                }
                .frame(width: size * 0.34, height: size * 0.12)
                .shadow(color: d.1.opacity(0.35), radius: size * 0.03, y: size * 0.02)
                .rotationEffect(.degrees(d.4))
                .offset(x: pop * size * 0.06, y: -pop * size * 0.04)
                .position(x: d.2 * size, y: d.3 * size)
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(angle)
    }
}

// MARK: Bot

/// The in-app bot: a front-facing 3D glass cursor with a dark glass face, glowing eyes, a small mouth, glossy feet and
/// a soft contact shadow. Every expression is a parameter, so `LivelyBot` can animate it.
struct GlassBot: View {
    enum Eyes: Equatable { case happy, open, wide }
    enum Style: Equatable {
        case brand
        /// White glass with the face tinted (Clicky avatars).
        case white(face: Color)
    }

    var sparkles = false
    var glow = true
    var style: Style = .brand
    /// 0 = open, 1 = shut.
    var blink: CGFloat = 0
    var eyes: Eyes = .happy
    /// Where the eyes look, −1…1 on each axis.
    var look: CGPoint = .zero
    /// 0 = smile, 1 = open (speaking). nil = no mouth.
    var mouth: CGFloat? = 0
    /// Height above the floor as a fraction of the size (the shadow shrinks as it rises).
    var lift: CGFloat = 0
    /// Squash (< 1) and stretch (> 1) of the body, anchored at the feet.
    var stretch: CGFloat = 1
    var tilt: Double = 0
    var blushing = true
    /// 0…1: the dashes pop out a little (hover, hop).
    var pop: CGFloat = 0

    static let bodyShape = RoundedPolygon(points: [CGPoint(x: 0.5, y: -0.1), CGPoint(x: 1.0, y: 0.86),
                                              CGPoint(x: 0.5, y: 0.78), CGPoint(x: 0.0, y: 0.86)], radius: 0.15)

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack {
                if glow { contactShadow(w) }
                ZStack {
                    // The glass body is rendered once into one image and only moved while animating: its ~15
                    // blurred layers are far too costly to redraw every frame. Padded so the head isn't clipped.
                    ZStack {
                        feet(w)
                        GlassSolid(shape: Self.bodyShape, size: w, palette: bodyPalette,
                                   highlight: CGPoint(x: 0.36, y: 0.22), highlightAngle: -55)
                            .equatable()
                        if blushing { blush(w) }
                    }
                    .frame(width: w, height: w)
                    .padding(w * 0.2)
                    .drawingGroup()
                    .padding(-w * 0.2)
                    face(w)
                }
                .frame(width: w, height: w)
                .scaleEffect(x: 2 - stretch, y: stretch, anchor: .bottom)
                .rotationEffect(.degrees(tilt), anchor: .bottom)
                .offset(y: -lift * w)
                if sparkles {
                    SparkleDashes(size: w * 0.5, pop: pop)
                        .padding(w * 0.1).drawingGroup().padding(-w * 0.1)
                        .position(x: w * 1.08, y: w * 0.2 - lift * w)
                }
            }
            .frame(width: w, height: w)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var bodyPalette: GlassPalette {
        if case .white = style { return .white }
        return .brand
    }

    private var faceColors: [Color] {
        if case .white(let face) = style { return [face.lighter(0.08), face] }
        return [Color(hex: 0x16235F), Color(hex: 0x0C1240)]
    }

    private var eyeGlow: Color {
        if case .white = style { return .white }
        return Color(hex: 0x7FE3FF)
    }

    private func contactShadow(_ w: CGFloat) -> some View {
        BotContactShadow(size: w).scaleEffect(max(0.55, 1 - lift * 3)).position(x: w * 0.5, y: w * 0.955)
    }

    private func feet(_ w: CGFloat) -> some View {
        let palette: GlassPalette = { if case .white = style { return .white }; return .feet }()
        return ForEach([-1.0, 1.0], id: \.self) { side in
            GlassSolid(shape: Capsule(style: .continuous), size: w * 0.28, palette: palette,
                       highlight: CGPoint(x: 0.35, y: 0.3), highlightAngle: -10)
                .equatable()
                .frame(width: w * 0.28, height: w * 0.28)
                .scaleEffect(x: 1, y: 0.48)
                .rotationEffect(.degrees(side * -4))
                .position(x: w * (0.5 + side * 0.24), y: w * 0.875)
        }
    }

    private func blush(_ w: CGFloat) -> some View {
        ForEach([-1.0, 1.0], id: \.self) { side in
            Ellipse()
                .fill(Brand.blush.opacity(style == .brand ? 0.55 : 0.4))
                .frame(width: w * 0.085, height: w * 0.042)
                .blur(radius: w * 0.01)
                .position(x: w * (0.5 + side * 0.305), y: w * 0.655)
        }
    }

    private func face(_ w: CGFloat) -> some View {
        let plate = RoundedRectangle(cornerRadius: w * 0.11, style: .continuous)
        let lookX = look.x * w * 0.035, lookY = look.y * w * 0.022
        return ZStack {
            // Dark glass face plate, set into the body.
            plate.fill(LinearGradient(colors: faceColors, startPoint: .top, endPoint: .bottom))
            plate.stroke(Color.black.opacity(0.35), lineWidth: w * 0.02).blur(radius: w * 0.012).mask(plate)
            plate.fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.45)))
                .padding(w * 0.012)
            plate.stroke(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                         lineWidth: max(0.5, w * 0.006))
            // Eyes.
            ForEach([-1.0, 1.0], id: \.self) { side in
                eye(w)
                    .position(x: w * (0.24 + side * 0.1) + lookX, y: w * 0.105 + lookY)
            }
            if let mouth {
                let mouthShape = BotMouth(open: mouth)
                ZStack {
                    if mouth > 0.02 { mouthShape.fill(Color(hex: 0xFF8FB3).opacity(0.9)) }
                    mouthShape.stroke(eyeGlow, style: StrokeStyle(lineWidth: max(0.8, w * 0.012), lineCap: .round, lineJoin: .round))
                }
                .frame(width: w * 0.065, height: w * 0.028)
                .shadow(color: eyeGlow.opacity(0.6), radius: w * 0.012)
                .position(x: w * 0.24 + lookX * 0.6, y: w * 0.168 + lookY * 0.6)
            }
        }
        .frame(width: w * 0.48, height: w * 0.225)
        .position(x: w * 0.5, y: w * 0.565)
    }

    @ViewBuilder
    private func eye(_ w: CGFloat) -> some View {
        let open = max(0.1, 1 - blink)
        Group {
            switch eyes {
            case .happy:
                ChevronEye()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: max(1.2, w * 0.024), lineCap: .round))
                    .frame(width: w * 0.085, height: w * 0.035)
            case .open, .wide:
                Capsule(style: .continuous)
                    .fill(Color.white)
                    .frame(width: w * (eyes == .wide ? 0.056 : 0.045), height: w * (eyes == .wide ? 0.09 : 0.075))
            }
        }
        .scaleEffect(x: 1, y: open, anchor: .center)
        .shadow(color: eyeGlow.opacity(0.9), radius: w * 0.02)
        .shadow(color: eyeGlow.opacity(0.5), radius: w * 0.045)
    }
}

// MARK: Logo

/// The app icon: a light macOS squircle with a 3D glass cursor, smiling eyes and three "click" dashes. Drawn on the
/// macOS icon grid (tile = 80.5% of the canvas).
struct AppLogo: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let tile = s * 0.805
            let tileShape = RoundedRectangle(cornerRadius: tile * 0.225, style: .continuous)
            ZStack {
                ZStack {
                    tileShape.fill(LinearGradient(colors: [.white, Color(hex: 0xEEF1F7), Color(hex: 0xDFE4EE)],
                                                  startPoint: .top, endPoint: .bottom))
                    tileShape.fill(RadialGradient(colors: [Brand.blue.opacity(0.1), .clear], center: UnitPoint(x: 0.6, y: 0.65),
                                                  startRadius: 0, endRadius: tile * 0.55))
                    // Glass edge: bright on top, a little shade at the bottom.
                    tileShape.strokeBorder(LinearGradient(colors: [.white, .white.opacity(0.4), Color(hex: 0xB9C2D3)],
                                                          startPoint: .top, endPoint: .bottom),
                                           lineWidth: tile * 0.012)
                }
                .frame(width: tile, height: tile)
                .shadow(color: .black.opacity(0.28), radius: tile * 0.03, y: tile * 0.018)

                CursorGlyph(size: s * 0.66)
                    .position(x: s * 0.48, y: s * 0.54)

                SparkleDashes(size: s * 0.27)
                    .position(x: s * 0.75, y: s * 0.34)
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// The logo's side-facing glass cursor with the bot's face (dark glass visor, glowing ^ ^ eyes, a smile), casting a
/// soft colored shadow. `face` tints the visor (white glyph on the Talk avatar).
struct CursorGlyph: View {
    var size: CGFloat
    var palette: GlassPalette = .brand
    var shadow = true
    var face: [Color] = [Color(hex: 0x16235F), Color(hex: 0x0C1240)]
    var eyeGlow = Color(hex: 0x7FE3FF)

    static let shape = RoundedPolygon(points: [CGPoint(x: 0.1, y: 0.05), CGPoint(x: 0.93, y: 0.55),
                                               CGPoint(x: 0.56, y: 0.66), CGPoint(x: 0.28, y: 0.95)], radius: 0.1)

    var body: some View {
        let plate = RoundedRectangle(cornerRadius: size * 0.075, style: .continuous)
        ZStack {
            if shadow {
                Self.shape.fill(palette.deep.opacity(0.5))
                    .frame(width: size, height: size)
                    .blur(radius: size * 0.05)
                    .offset(x: size * 0.035, y: size * 0.07)
            }
            GlassSolid(shape: Self.shape, size: size, palette: palette, highlight: CGPoint(x: 0.28, y: 0.26), highlightAngle: 30)
            // The bot's face, turned with the cursor.
            ZStack {
                plate.fill(LinearGradient(colors: face, startPoint: .top, endPoint: .bottom))
                plate.stroke(Color.black.opacity(0.35), lineWidth: size * 0.018).blur(radius: size * 0.01).mask(plate)
                plate.fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5)))
                    .padding(size * 0.008)
                plate.stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                             lineWidth: max(0.5, size * 0.006))
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ChevronEye()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: max(1, size * 0.026), lineCap: .round))
                        .frame(width: size * 0.075, height: size * 0.032)
                        .shadow(color: eyeGlow.opacity(0.9), radius: size * 0.018)
                        .position(x: size * (0.17 + side * 0.075), y: size * 0.065)
                }
                BotMouth(open: 0)
                    .stroke(eyeGlow, style: StrokeStyle(lineWidth: max(0.6, size * 0.012), lineCap: .round))
                    .frame(width: size * 0.05, height: size * 0.02)
                    .position(x: size * 0.17, y: size * 0.118)
            }
            .frame(width: size * 0.34, height: size * 0.16)
            .rotationEffect(.degrees(31))
            .position(x: size * 0.5, y: size * 0.47)
        }
        .frame(width: size, height: size)
    }
}

// MARK: Motion

/// The soft shadow under the bot: blue light pooling in Dark Mode. A radial gradient, which looks like a blur but is
/// cheap to scale while the bot floats.
struct BotContactShadow: View {
    var size: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let tint = scheme == .dark ? Brand.blue.opacity(0.5) : Color.black.opacity(0.26)
        Ellipse()
            .fill(RadialGradient(colors: [tint, tint.opacity(0)], center: .center, startRadius: 0, endRadius: size * 0.42))
            .frame(width: size * 0.9, height: size * 0.16)
    }
}

/// Drives the bot's discrete moments (blinks, glances toward the pointer, hops) with timers, so SwiftUI only
/// re-describes the bot when something actually changes. Continuous motion (float, breath, sway, talking mouth) are
/// repeating animations that SwiftUI interpolates without rebuilding the bot.
@MainActor
final class BotDriver: ObservableObject {
    @Published var blink: CGFloat = 0
    @Published var look: CGPoint = .zero
    @Published var hop = false
    @Published var floating = false
    @Published var swaying = false
    @Published var talking = false

    weak var view: NSView?
    var lookingUp = false
    private var blinkTimer: Timer?
    private var lookTimer: Timer?
    private var still = false

    func start(still: Bool) {
        stop()
        self.still = still
        scheduleBlink()
        // Follow the pointer, a dozen checks a second; nothing happens while it rests.
        lookTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 12, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.followPointer() }
        }
        guard !still else { return }
        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) { floating = true }
        withAnimation(.easeInOut(duration: 3.1).repeatForever(autoreverses: true)) { swaying = true }
    }

    func stop() {
        blinkTimer?.invalidate()
        lookTimer?.invalidate()
        blinkTimer = nil
        lookTimer = nil
    }

    /// A happy hop: up fast, a springy landing.
    func hopNow() {
        guard !still, !hop else { return }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.5)) { hop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.55)) { self?.hop = false }
        }
    }

    func setTalking(_ on: Bool) {
        guard on != talking else { return }
        if on, !still {
            withAnimation(.easeInOut(duration: 0.17).repeatForever(autoreverses: true)) { talking = true }
        } else {
            withAnimation(.easeOut(duration: 0.15)) { talking = false }
        }
    }

    /// Natural blinks every 2.5–5.5 s (8 s with Reduce Motion), sometimes twice in a row.
    private func scheduleBlink() {
        let wait = still ? 8 : Double.random(in: 2.5...5.5)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: wait, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.blinkOnce()
                if !self.still, Double.random(in: 0...1) < 0.3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { self.blinkOnce() }
                }
                self.scheduleBlink()
            }
        }
    }

    private func blinkOnce() {
        withAnimation(.easeIn(duration: 0.07)) { blink = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { [weak self] in
            withAnimation(.easeOut(duration: 0.11)) { self?.blink = 0 }
        }
    }

    private func followPointer() {
        var target = CGPoint.zero
        if lookingUp {
            target = CGPoint(x: 0.7, y: -0.9)
        } else if let view, let window = view.window {
            let rect = window.convertToScreen(view.convert(view.bounds, to: nil))
            let mouse = NSEvent.mouseLocation
            let reach: CGFloat = 260
            target = CGPoint(x: max(-1, min(1, (mouse.x - rect.midX) / reach)),
                             y: max(-1, min(1, -(mouse.y - rect.midY) / reach)))
        }
        guard abs(target.x - look.x) > 0.04 || abs(target.y - look.y) > 0.04 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { look = target }
    }
}

private struct ProbeView: NSViewRepresentable {
    let driver: BotDriver
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        driver.view = view
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) { driver.view = nsView }
}

/// The bot, alive (spec 016 US3): it breathes, floats with its shadow reacting, sways, blinks naturally (sometimes
/// twice), follows the pointer with its eyes, hops when you point at it, and reacts to Clicky's state: listening (eyes
/// wide, leaning in), thinking (looking up), speaking (its mouth moves). With Reduce Motion it stands still and blinks
/// every 8 s. Measure changes with `MyClicky --bench-bot`.
struct LivelyBot: View {
    var sparkles = false
    @StateObject private var driver = BotDriver()
    @StateObject private var hovering = Box(false)

    var body: some View {
        let still = DisplayPrefs.shared.reduceMotion
        let state = AppModel.shared.talkState
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack {
                BotContactShadow(size: w)
                    .scaleEffect(driver.hop ? 0.6 : (driver.floating ? 0.84 : 1))
                    .opacity(driver.hop ? 0.5 : (driver.floating ? 0.8 : 1))
                    .position(x: w * 0.5, y: w * 0.955)
                GlassBot(sparkles: sparkles, glow: false,
                         blink: driver.blink,
                         eyes: state == .listening ? .wide : (state == .thinking ? .open : .happy),
                         look: driver.look,
                         mouth: driver.talking ? 0.8 : 0,
                         lift: 0.025,
                         pop: hovering.value || driver.hop ? 1 : 0)
                    .frame(width: w, height: w)
                    .scaleEffect(x: driver.hop ? 0.95 : (driver.floating ? 0.993 : 1.006),
                                 y: driver.hop ? 1.06 : (driver.floating ? 1.01 : 0.992), anchor: .bottom)
                    .rotationEffect(.degrees((driver.swaying ? 2.2 : -2.2) + (state == .listening ? -3 : 0)), anchor: .bottom)
                    .offset(y: driver.floating ? -w * 0.035 : 0)
                    .offset(y: driver.hop ? -w * 0.14 : 0)
            }
            .frame(width: w, height: w)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(ProbeView(driver: driver))
        .contentShape(Rectangle())
        .onHover { inside in
            withAnimation(Motion.bouncy) { hovering.value = inside }
            if inside { driver.hopNow() }
        }
        .onAppear { driver.start(still: still) }
        .onDisappear { driver.stop() }
        .onChange(of: state) { _, new in
            driver.setTalking(new == .speaking)
            driver.lookingUp = new == .thinking
        }
        .animation(Motion.standard, value: state)
        .accessibilityHidden(true)
    }
}

// MARK: Avatars

/// A Clicky's avatar, Apple Contacts style: a circle in the Clicky's color (light at the top, deeper at the bottom)
/// with a white glass bot whose face takes the same color.
struct BotAvatar: View {
    var ring: Color
    var size: CGFloat = 42

    var body: some View {
        let top = ring.adjusted(saturation: 0.1, brightness: 0.04)
        let bottom = ring.adjusted(saturation: 0.38, brightness: -0.2)
        let face = ring.adjusted(saturation: 0.55, brightness: -0.45)
        ZStack {
            Circle().fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
            Circle().fill(RadialGradient(colors: [.white.opacity(0.35), .clear], center: UnitPoint(x: 0.35, y: 0.2),
                                         startRadius: 0, endRadius: size * 0.55))
            GlassBot(glow: false, style: .white(face: face), mouth: size >= 40 ? 0 : nil, blushing: size >= 40)
                .frame(width: size * 0.66, height: size * 0.66)
                .offset(y: size * 0.07)
                .shadow(color: bottom.opacity(0.5), radius: size * 0.03, y: size * 0.02)
            Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// Talk's avatar: the logo's cursor in white glass on the brand gradient.
struct TalkAvatar: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Brand.sky, Brand.blue, Brand.indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(RadialGradient(colors: [.white.opacity(0.35), .clear], center: UnitPoint(x: 0.35, y: 0.2),
                                         startRadius: 0, endRadius: size * 0.55))
            CursorGlyph(size: size * 0.66, palette: .white, shadow: false, face: [Color(hex: 0x2A6BEA), Color(hex: 0x3A2FB8)],
                        eyeGlow: .white)
                .shadow(color: Brand.deepIndigo.opacity(0.45), radius: size * 0.04, y: size * 0.03)
                .offset(x: -size * 0.01, y: size * 0.01)
            Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

extension Color {
    /// Shifts saturation and brightness (−1…1 each), keeping the hue.
    func adjusted(saturation ds: Double, brightness db: Double) -> Color {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: min(1, max(0, Double(s) + ds)),
                     brightness: min(1, max(0, Double(b) + db)), opacity: Double(a))
    }
}
