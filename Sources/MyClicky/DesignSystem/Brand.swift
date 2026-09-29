import SwiftUI

/// MyClicky's visual system (spec 013, `references/myclicky/visual-system.png`): liquid-glass cursor characters
/// on near-black navy, soft neon rim glow, blue-violet refraction and warm edge highlights.
enum Brand {
    static let midnight = Color(hex: 0x080C1C)
    static let deepNavy = Color(hex: 0x11192F)
    static let electricBlue = Color(hex: 0x3B82F6)
    static let cyanGlow = Color(hex: 0x47D7FF)
    static let violet = Color(hex: 0x7C5CFF)
    static let magenta = Color(hex: 0xE35BFF)
    static let warmGlass = Color(hex: 0xFFD2B8)
    static let iceWhite = Color(hex: 0xF7FAFF)
}

/// A polygon with rounded corners. Points are fractions of the rect (0…1); `radius` is a fraction of its width.
struct RoundedPolygon: Shape {
    var points: [CGPoint]
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let p = points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        let r = radius * rect.width
        var path = Path()
        let n = p.count
        let start = CGPoint(x: (p[n - 1].x + p[0].x) / 2, y: (p[n - 1].y + p[0].y) / 2)
        path.move(to: start)
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
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

/// Paints any shape as liquid glass: blue-violet body, lighter top, violet/magenta edge, warm rim highlights and a
/// neon glow. `size` is the shape's width, used to scale strokes and blurs.
struct GlassMaterial<S: Shape>: View {
    enum Tone { case deep, icy }

    var shape: S
    var size: CGFloat
    var glow = true
    var tone: Tone = .deep
    /// Where the light comes from (warm highlight side).
    var light: UnitPoint = .topLeading
    /// Scale of a second, inner edge that makes the glass look thick (nil = none), and where it shrinks toward.
    var inner: CGFloat? = nil
    var innerAnchor: UnitPoint = .center

    var body: some View {
        let centerColors: [Color] = tone == .deep
            ? [Color(hex: 0x0A1270), Color(hex: 0x1636E0), Color(hex: 0x3F7BFF), Color(hex: 0xA9C6FF)]
            : [Color(hex: 0x4F74F0), Color(hex: 0x8FAEFF), Color(hex: 0xD3E1FF), Color(hex: 0xF4F8FF)]
        ZStack {
            if glow {
                shape.fill(AngularGradient(colors: [Brand.cyanGlow, Brand.electricBlue, Brand.violet, Brand.magenta,
                                                    Brand.electricBlue, Brand.cyanGlow], center: .center))
                    .blur(radius: size * 0.08)
                    .opacity(0.9)
            }
            // Body: deep refraction in the middle, brighter toward the edges.
            shape.fill(RadialGradient(colors: centerColors, center: UnitPoint(x: 0.52, y: 0.6),
                                      startRadius: 0, endRadius: size * 0.6))
            shape.fill(LinearGradient(colors: [Brand.magenta.opacity(0.6), Brand.violet.opacity(0.3), .clear],
                                      startPoint: .leading, endPoint: UnitPoint(x: 0.4, y: 0.5)))
            shape.fill(LinearGradient(colors: [Color(hex: 0xCFE0FF).opacity(tone == .deep ? 0.38 : 0.7), .clear],
                                      startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.42)))
            // Thick band of light just inside the edge.
            shape.stroke(AngularGradient(colors: [Color(hex: 0xBFE9FF), Brand.warmGlass, Color(hex: 0x6E8BFF),
                                                  Brand.violet, Brand.magenta, Color(hex: 0xE9D9FF), Brand.iceWhite,
                                                  Brand.iceWhite, Color(hex: 0xBFE9FF)], center: .center),
                         lineWidth: size * 0.13)
                .blur(radius: size * 0.03)
                .mask(shape)
                .opacity(0.9)
            if let inner {
                shape.stroke(Brand.iceWhite.opacity(0.5), lineWidth: max(0.5, size * 0.01))
                    .scaleEffect(inner, anchor: innerAnchor)
                    .blur(radius: size * 0.004)
            }
            // Crisp glass edge.
            shape.stroke(AngularGradient(colors: [Brand.cyanGlow, Brand.warmGlass, Brand.electricBlue, Color(hex: 0xC9A6FF),
                                                  .white, .white, Brand.cyanGlow], center: .center),
                         lineWidth: max(1, size * 0.014))
        }
        .compositingGroup()
    }
}

/// Neon "^" eye with a soft glow.
struct GlowingEye: View {
    var size: CGFloat

    var body: some View {
        let line = StrokeStyle(lineWidth: max(1.5, size * 0.3), lineCap: .round, lineJoin: .round)
        ZStack {
            ChevronEye().stroke(Brand.cyanGlow, style: line).blur(radius: size * 0.18).opacity(0.9)
            ChevronEye().stroke(.white, style: line)
        }
        .frame(width: size, height: size * 0.52)
    }
}

/// Three neon dashes radiating up and to the right ("click!").
struct SparkleDashes: View {
    var size: CGFloat
    /// Rotation of the whole fan.
    var angle: Angle = .zero

    var body: some View {
        let dashes: [(Color, Color, CGFloat, CGFloat, Double)] = [ // colors, x, y (fractions of size), angle
            (Brand.cyanGlow, Color(hex: 0x6FE7FF), 0.30, 0.18, -55),
            (Color(hex: 0x6FC8FF), Brand.violet, 0.58, 0.46, -28),
            (Brand.violet, Brand.magenta, 0.70, 0.80, 0),
        ]
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let d = dashes[i]
                let dash = Capsule(style: .continuous)
                ZStack {
                    dash.fill(LinearGradient(colors: [d.0, d.1], startPoint: .leading, endPoint: .trailing))
                        .blur(radius: size * 0.06)
                    dash.fill(LinearGradient(colors: [d.0.lighter(0.25), d.1.lighter(0.2)], startPoint: .leading,
                                             endPoint: .trailing))
                    dash.stroke(.white.opacity(0.6), lineWidth: max(0.5, size * 0.012))
                }
                .frame(width: size * 0.36, height: size * 0.12)
                .rotationEffect(.degrees(d.4))
                .position(x: d.2 * size, y: d.3 * size)
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(angle)
    }
}

/// The in-app bot (BOT.png): a front-facing glass cursor with two smiling eyes and two small glass feet.
/// `blink` closes the eyes (0 = open, 1 = shut).
struct GlassBot: View {
    var sparkles = false
    var glow = true
    var blink: CGFloat = 0

    static let bodyShape = RoundedPolygon(points: [CGPoint(x: 0.5, y: -0.16), CGPoint(x: 1.02, y: 0.88),
                                              CGPoint(x: 0.5, y: 0.8), CGPoint(x: -0.02, y: 0.88)], radius: 0.12)

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack {
                if glow { // light pooling on the floor
                    Ellipse().fill(Brand.electricBlue.opacity(0.55)).frame(width: w * 1.0, height: w * 0.16)
                        .blur(radius: w * 0.07).position(x: w * 0.5, y: w * 0.97)
                }
                GlassMaterial(shape: Self.bodyShape, size: w, glow: glow, inner: 0.84, innerAnchor: UnitPoint(x: 0.5, y: 0.6))
                    .frame(width: w, height: w)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    GlassMaterial(shape: Capsule(style: .continuous), size: w * 0.26, glow: false, tone: .icy)
                        .frame(width: w * 0.28, height: w * 0.15)
                        .rotationEffect(.degrees(side * -3))
                        .position(x: w * (0.5 + side * 0.31), y: w * 0.885)
                }
                ForEach([-1.0, 1.0], id: \.self) { side in
                    GlowingEye(size: w * 0.16)
                        .scaleEffect(x: 1, y: max(0.08, 1 - blink), anchor: .bottom)
                        .position(x: w * (0.5 + side * 0.15), y: w * 0.56)
                }
                if sparkles {
                    SparkleDashes(size: w * 0.55).position(x: w * 1.1, y: w * 0.22)
                }
            }
            .frame(width: w, height: w)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// The app logo (LOGO.png): a side-facing glass cursor with smiling eyes and sparkles on a glass tile.
/// Drawn on the macOS icon grid (tile = 80.5% of the canvas).
struct AppLogo: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let tile = s * 0.805
            let radius = tile * 0.225
            let tileShape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            ZStack {
                // Tile: dark glass with blue-violet bloom and a neon edge.
                ZStack {
                    tileShape.fill(LinearGradient(colors: [Color(hex: 0x1B1848), Color(hex: 0x0B1030), Color(hex: 0x0E1450)],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                    tileShape.fill(RadialGradient(colors: [Color(hex: 0x2A3BFF).opacity(0.55), Brand.violet.opacity(0.18), .clear],
                                                  center: UnitPoint(x: 0.62, y: 0.62), startRadius: 0, endRadius: tile * 0.6))
                    tileShape.stroke(AngularGradient(colors: [Brand.cyanGlow, Brand.electricBlue, Color(hex: 0x3A4BFF), Brand.violet,
                                                              Brand.magenta, Brand.warmGlass, Color(hex: 0xC8B8FF),
                                                              Brand.electricBlue, Brand.cyanGlow], center: .center),
                                     lineWidth: tile * 0.05)
                        .blur(radius: tile * 0.015)
                        .mask(tileShape)
                    tileShape.stroke(AngularGradient(colors: [Brand.cyanGlow, Color(hex: 0x5B8CFF), Brand.violet, Brand.magenta,
                                                              Brand.warmGlass, Color(hex: 0xA9C8FF), Brand.cyanGlow],
                                                     center: .center),
                                     lineWidth: tile * 0.01)
                    tileShape.inset(by: tile * 0.035)
                        .stroke(Color(hex: 0x9DB5FF).opacity(0.35), lineWidth: tile * 0.004)
                    // Glass reflection in the top-left corner.
                    Ellipse().fill(LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: tile * 0.3, height: tile * 0.34)
                        .blur(radius: tile * 0.02)
                        .position(x: tile * 0.17, y: tile * 0.2)
                        .mask(tileShape)
                }
                .frame(width: tile, height: tile)
                .shadow(color: Color(hex: 0x3D5BFF).opacity(0.6), radius: tile * 0.025)

                // Cursor.
                let cursor = RoundedPolygon(points: [CGPoint(x: 0.1, y: 0.05), CGPoint(x: 0.93, y: 0.55),
                                                     CGPoint(x: 0.56, y: 0.66), CGPoint(x: 0.28, y: 0.95)], radius: 0.09)
                let c = s * 0.71
                ZStack {
                    GlassMaterial(shape: cursor, size: c, inner: 0.84, innerAnchor: UnitPoint(x: 0.45, y: 0.5))
                    ForEach(0..<2, id: \.self) { i in
                        GlowingEye(size: c * 0.11)
                            .rotationEffect(.degrees(-8))
                            .position(x: c * (0.45 + CGFloat(i) * 0.16), y: c * (0.5 - CGFloat(i) * 0.02))
                    }
                }
                .frame(width: c, height: c)
                .position(x: s * 0.56, y: s * 0.53)

                SparkleDashes(size: s * 0.29)
                    .position(x: s * 0.77, y: s * 0.35)
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// The bot, alive: it blinks every few seconds and floats gently (greeting, welcome tour).
struct LivelyBot: View {
    var sparkles = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = t.truncatingRemainder(dividingBy: 4.2)
            let blink = phase < 0.16 ? CGFloat(sin(phase / 0.16 * .pi)) : 0
            GlassBot(sparkles: sparkles, blink: blink)
                .offset(y: CGFloat(sin(t * 1.6)) * 2.5)
        }
    }
}

/// Chat avatar: a small glass bot on navy with the chat's color as a soft ring (Clickys), or the app logo (Talk).
struct BotAvatar: View {
    var ring: Color
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [ring.opacity(0.28), Brand.deepNavy], center: .center,
                                         startRadius: 0, endRadius: size * 0.55))
            GlassBot(glow: false).frame(width: size * 0.6, height: size * 0.6).offset(y: size * 0.04)
            Circle().strokeBorder(ring.opacity(0.85), lineWidth: max(1, size * 0.04))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
