//
//  ArkExitScreen.swift
//  HAL
//
//  La fin de mission d'Ark One : le champ d'étoiles s'étire, le vaisseau
//  saute en FTL dans un éclair cyan, puis la console signe. Pas de mort de
//  tube cathodique ici — un vaisseau-colonie ne s'éteint pas, il appareille.
//

import AppKit

final class ArkJumpView: NSView {

    private struct Star {
        var angle: CGFloat
        var distance: CGFloat
        var speed: CGFloat
        var brightness: CGFloat
    }

    private let theme: ThemeDefinition
    private let maxRadius: CGFloat
    private var stars: [Star] = []

    private var start = Date()
    private var lastTick = Date()
    private var animationTask: Task<Void, Never>?

    /// Étoiles : dérive radiale, puis étirement pendant l'accélération.
    private static let starCount = 170
    private static let totalDuration: TimeInterval = 4.8

    override var isOpaque: Bool { true }
    override var isFlipped: Bool { true }

    init(frame frameRect: NSRect, panel: PanelView) {
        theme = panel.theme
        maxRadius = hypot(frameRect.width, frameRect.height) / 2 + 80
        super.init(frame: frameRect)
        seedStars()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    private func seedStars() {
        stars = (0..<Self.starCount).map { _ in
            Star(angle: .random(in: 0...(2 * .pi)),
                 distance: .random(in: 5...maxRadius),
                 speed: .random(in: 55...240),
                 brightness: .random(in: 0.18...0.9))
        }
    }

    private func update(delta: TimeInterval, elapsed: TimeInterval) {
        let acceleration = 1 + CGFloat(min(elapsed, 2.7)) * 1.6
        for index in stars.indices {
            stars[index].distance += stars[index].speed * CGFloat(delta) * acceleration
            if stars[index].distance > maxRadius {
                stars[index].angle = .random(in: 0...(2 * .pi))
                stars[index].distance = .random(in: 2...24)
                stars[index].speed = .random(in: 55...240)
                stars[index].brightness = .random(in: 0.18...0.9)
            }
        }
    }

    // MARK: - Déroulé

    func start(completion: @escaping () -> Void) {
        start = Date()
        lastTick = Date()

        animationTask = Task { @MainActor in
            let tickNanoseconds = UInt64((1.0 / 30.0) * 1_000_000_000)

            while !Task.isCancelled {
                let now = Date()
                let delta = now.timeIntervalSince(lastTick)
                lastTick = now
                let elapsed = now.timeIntervalSince(start)
                update(delta: delta, elapsed: elapsed)

                if elapsed >= Self.totalDuration {
                    break
                }
                needsDisplay = true
                try? await Task.sleep(nanoseconds: tickNanoseconds)
            }

            // Final frame
            needsDisplay = true
            completion()
        }
    }

    func stop() {
        animationTask?.cancel()
        animationTask = nil
    }

    // MARK: - Dessin

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        let elapsed = Date().timeIntervalSince(start)
        let palette = theme.palette

        for star in stars {
            let directionX = cos(star.angle)
            let directionY = sin(star.angle)
            let head = NSPoint(x: bounds.midX + directionX * star.distance,
                               y: bounds.midY + directionY * star.distance)
            let stretch = star.speed * (0.014 + 0.022 * CGFloat(min(elapsed, 2.7)))
            let tail = NSPoint(x: head.x - directionX * stretch, y: head.y - directionY * stretch)

            let path = NSBezierPath()
            path.move(to: tail)
            path.line(to: head)
            path.lineWidth = star.distance > maxRadius * 0.55 ? 1.5 : 1.0
            palette.accentSoft.withAlphaComponent(star.brightness).setStroke()
            path.stroke()
        }

        // Éclair de saut FTL.
        if elapsed > 2.30, elapsed < 2.95 {
            let alpha = max(0, 1 - abs(elapsed - 2.62) / 0.33)
            NSColor.white.withAlphaComponent(0.85 * alpha).setFill()
            bounds.fill()
        }

        // Signature de la console.
        if elapsed > 3.0 {
            drawFarewell(progress: min(1, (elapsed - 3.0) / 0.65))
        }
    }

    private func drawFarewell(progress: Double) {
        let palette = theme.palette
        let alpha = CGFloat(progress)
        let text = theme.copy.farewell

        let font = theme.type.font(46, bold: true)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: palette.accentSoft.withAlphaComponent(alpha),
            .kern: 4,
            .shadow: theme.type.glow(palette.accent, radius: 14)
                ?? NSShadow()
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (bounds.width - size.width) / 2,
                              y: bounds.midY - size.height - 8),
                  withAttributes: attrs)

        let subAttrs = theme.type.attributes(10, color: palette.dim.withAlphaComponent(alpha),
                                             bold: true, kern: 2.2)
        let sub = "CENT-COM · MISSION LOG CLOSED"
        let subSize = sub.size(withAttributes: subAttrs)
        sub.draw(at: NSPoint(x: (bounds.width - subSize.width) / 2,
                             y: bounds.midY + 18),
                 withAttributes: subAttrs)

        let rule = NSBezierPath()
        let halfWidth: CGFloat = 150
        rule.move(to: NSPoint(x: bounds.midX - halfWidth, y: bounds.midY + 10))
        rule.line(to: NSPoint(x: bounds.midX + halfWidth, y: bounds.midY + 10))
        palette.accent.withAlphaComponent(alpha * 0.5).setStroke()
        rule.lineWidth = 1
        rule.stroke()
    }
}

enum ArkExitScreen {

@MainActor
    static func show(panel: PanelView, then completion: @escaping () -> Void) {
        guard let screen = NSScreen.main else {
            completion()
            return
        }

        panel.theme.voice.say(panel.theme.copy.spokenFarewell)

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = true
        window.backgroundColor = .black
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = ArkJumpView(frame: screen.frame, panel: panel)
        window.contentView = view

        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        view.start {
            window.orderOut(nil)
            window.close()
            completion()
        }
    }
}
