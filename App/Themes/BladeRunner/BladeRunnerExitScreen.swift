//
//  BladeRunnerExitScreen.swift
//  HAL
//
//  La fin du réplicant. Au quit, le panneau gelé s'affiche plein écran,
//  ses écrans tombent un à un dans le noir, la pluie de néon achève de
//  l'effacer. Alors « TIME TO DIE » apparaît, et ses lettres glissent et
//  se dissolvent comme des larmes dans la pluie.
//

import AppKit

final class BladeRunnerExitView: NSView {

    /// Panneau figé, rendu une fois pour toutes : le dernier relevé avant
    /// la retraite.
    private let cockpit: NSImage
    private let cockpitRect: NSRect

    /// Zones des écrans, converties en coordonnées de la vue, dans l'ordre
    /// d'extinction.
    private let screenRects: [NSRect]

    private let theme: ThemeDefinition
    private let farewell: String

    /// Ordre de disparition des lettres, et leur chute propre.
    private let letterDeathOrder: [Int]
    private let letterFall: [CGFloat]
    private let letterShake: [CGFloat]

    private var start: Date?
    private var animationTask: Task<Void, Never>?

    private static let cascadeDuration: TimeInterval = 2.0
    private static let rainDuration: TimeInterval = 1.0
    private static let farewellDuration: TimeInterval = 2.4
    private static let totalDuration: TimeInterval =
        cascadeDuration + rainDuration + farewellDuration

    override var isOpaque: Bool { true }
    override var isFlipped: Bool { true }

    init(frame frameRect: NSRect, panel: PanelView) {
        let margin: CGFloat = 90
        let panelHeight = panel.panelHeight
        let panelWidth = panel.panelWidth
        let scale = min((frameRect.height - margin * 2) / panelHeight,
                        (frameRect.width - margin * 2) / panelWidth)
        let size = NSSize(width: panelWidth * scale,
                          height: panelHeight * scale)
        let origin = NSPoint(x: (frameRect.width - size.width) / 2,
                             y: (frameRect.height - size.height) / 2)

        cockpit = Self.render(panel: panel)
        cockpitRect = NSRect(origin: origin, size: size)
        theme = panel.theme
        farewell = panel.theme.copy.farewell

        var converted: [NSRect] = []
        for rect in panel.dashboardScreenRects {
            let convertedX = origin.x + rect.minX * scale
            let convertedY = origin.y + rect.minY * scale
            converted.append(NSRect(x: convertedX, y: convertedY,
                                    width: rect.width * scale,
                                    height: rect.height * scale))
        }
        screenRects = converted
        letterDeathOrder = (0..<farewell.count).shuffled()
        letterFall = (0..<farewell.count).map { _ in CGFloat.random(in: 14...46) }
        letterShake = (0..<farewell.count).map { _ in CGFloat.random(in: -3...3) }
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    // MARK: - Rendu du panneau

    private static func render(panel: PanelView) -> NSImage {
        let backing = NSScreen.main?.backingScaleFactor ?? 2
        let pointSize = panel.bounds.size
        let pixelSize = NSSize(width: pointSize.width * backing,
                               height: pointSize.height * backing)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(pixelSize.width),
            pixelsHigh: Int(pixelSize.height),
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        ) else {
            return NSImage(size: pointSize)
        }
        rep.size = pointSize
        panel.cacheDisplay(in: panel.bounds, to: rep)
        let image = NSImage(size: pointSize)
        image.addRepresentation(rep)
        return image
    }

    // MARK: - Déroulé

    func start(onCompletion completion: @escaping () -> Void) {
        start = Date()

        animationTask = Task { @MainActor in
            let tickNanoseconds = UInt64((1.0 / 30.0) * 1_000_000_000)

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start ?? Date())
                if elapsed >= Self.totalDuration {
                    break
                }
                needsDisplay = true
                try? await Task.sleep(nanoseconds: tickNanoseconds)
            }

            // Final frame
            needsDisplay = true

            // Wait for completion delay
            try? await Task.sleep(nanoseconds: UInt64((Self.totalDuration + 0.4) * 1_000_000_000))
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

        let elapsed = Date().timeIntervalSince(start ?? Date())
        let cascade = min(1, elapsed / Self.cascadeDuration)
        drawCockpit(cascade: cascade)

        // La pluie et le néon recouvrent le panneau, puis s'éteignent.
        let rainProgress = max(0, min(1,
            (elapsed - Self.cascadeDuration) / Self.rainDuration))
        if rainProgress > 0 || cascade > 0.75 {
            drawNeonRain(progress: rainProgress)
        }

        let farewellProgress = (elapsed - Self.cascadeDuration - Self.rainDuration)
            / Self.farewellDuration
        if farewellProgress > 0 {
            drawFarewell(progress: min(1, farewellProgress))
        }

        drawScanlines()
    }

    /// Le panneau s'éteint écran par écran, du bas vers le haut.
    private func drawCockpit(cascade: Double) {
        cockpit.draw(in: cockpitRect)

        guard cascade > 0 else { return }
        let count = Double(screenRects.count)

        for (index, rect) in screenRects.enumerated() {
            let death = cascade * count - Double(index)
            guard death > 0 else { continue }
            let darkness = min(1, death)
            let flicker = darkness < 1 ? Double.random(in: 0.55...1.0) : 1.0
            NSColor.black.withAlphaComponent(darkness * flicker).setFill()
            NSBezierPath(rect: rect).fill()
        }

        if cascade >= 1 {
            NSColor.black.setFill()
            cockpitRect.fill()
        }
    }

    /// Pluie rose et cyan, puis un voile noir pendant que le panneau
    /// s'efface. La ville ne meurt pas : elle cesse d'être regardée.
    private func drawNeonRain(progress: Double) {
        let palette = theme.palette
        let time = Date().timeIntervalSinceReferenceDate

        if progress > 0 {
            let veil = cockpitRect.insetBy(dx: -60, dy: -60)
            NSColor.black.withAlphaComponent(min(0.96, progress * 1.15)).setFill()
            veil.fill()
        }

        for index in 0..<90 {
            let seed = Double(index) * 0.6180339887
            let streakX = CGFloat(seed.truncatingRemainder(dividingBy: 1)) * bounds.width
            let speed = 90.0 + Double((index * 17) % 120)
            let span = Double(bounds.height + 100)
            let streakY = CGFloat((time * speed + Double(index) * 43)
                .truncatingRemainder(dividingBy: span)) - 50
            let length = CGFloat(14 + (index % 6) * 6)
            let color = index % 3 == 0 ? palette.accentSoft : palette.accent
            let alpha = 0.10 + CGFloat(index % 4) * 0.045

            color.withAlphaComponent(alpha).setStroke()
            let streak = NSBezierPath()
            streak.move(to: NSPoint(x: streakX, y: streakY))
            streak.line(to: NSPoint(x: streakX - 4, y: streakY + length))
            streak.lineWidth = 0.9
            streak.stroke()
        }

        // Halo rose au centre : la dernière lueur de la ville.
        if let glow = NSGradient(colors: [
            palette.accentSoft.withAlphaComponent(0.10 * (1 - progress)),
            .clear
        ]) {
            glow.draw(in: cockpitRect.insetBy(dx: -80, dy: -80),
                      relativeCenterPosition: .zero)
        }
    }

    /// « TIME TO DIE » : chaque lettre perd la vie à son tour, glisse et
    /// se dissout dans la pluie.
    private func drawFarewell(progress: Double) {
        let palette = theme.palette
        let font = theme.type.font(68, bold: true)
        let letters = farewell.map(String.init)
        let widths = letters.map { $0.size(withAttributes: [.font: font]).width }
        let totalWidth = widths.reduce(0, +)

        let dead = Int(progress * Double(letters.count))
        let gone = Set(letterDeathOrder.prefix(dead))
        let dying = Set(letterDeathOrder.prefix(min(letters.count, dead + 1)))

        var letterX = (bounds.width - totalWidth) / 2
        let baseY = (bounds.height - font.pointSize) / 2

        for (index, letter) in letters.enumerated() {
            defer { letterX += widths[index] }
            guard !gone.contains(index) else { continue }

            let fall = dying.contains(index) ? letterFall[index] * CGFloat(progress) : 0
            let shake = dying.contains(index)
                ? letterShake[index] * CGFloat(progress)
                : 0
            let alpha: CGFloat = dying.contains(index)
                ? max(0, 1 - CGFloat(progress) * 1.4)
                : 1

            var attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: palette.accentSoft.withAlphaComponent(alpha),
                .kern: 2.0
            ]
            if let glow = theme.type.glow(palette.accentSoft, radius: 14) {
                attrs[.shadow] = glow
            }

            letter.draw(at: NSPoint(x: letterX + shake, y: baseY + fall),
                        withAttributes: attrs)

            // La lettre qui meurt laisse une traînée de pluie.
            if dying.contains(index) {
                palette.accent.withAlphaComponent(alpha * 0.45).setStroke()
                let trail = NSBezierPath()
                trail.move(to: NSPoint(x: letterX, y: baseY + fall))
                trail.line(to: NSPoint(x: letterX - 2, y: baseY + fall + 40))
                trail.lineWidth = 0.8
                trail.stroke()
            }
        }

        let caption = "LOS ANGELES · NOVEMBER 2019"
        let captionAttrs = theme.type.attributes(
            9, color: palette.dim.withAlphaComponent(CGFloat(1 - progress)),
            bold: true, kern: 2.4)
        let captionWidth = caption.size(withAttributes: captionAttrs).width
        caption.draw(at: NSPoint(x: (bounds.width - captionWidth) / 2,
                                 y: (bounds.height + font.pointSize) / 2 + 10),
                     withAttributes: captionAttrs)
    }

    /// Le balayage du tube reste présent jusqu'au noir final.
    private func drawScanlines() {
        NSColor.black.withAlphaComponent(0.22).setFill()
        var lineY: CGFloat = 0
        while lineY < bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: lineY,
                                      width: bounds.width, height: 1)).fill()
            lineY += 3
        }
    }
}

enum BladeRunnerExitScreen {

    /// Affiche le panneau fourni, le regarde mourir, puis termine l'app.
@MainActor
    static func show(panel: PanelView, then completion: @escaping () -> Void) {
        let screen = NSScreen.main?.frame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let window = NSWindow(contentRect: screen,
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.backgroundColor = .black
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.hasShadow = false

        let view = BladeRunnerExitView(frame: NSRect(origin: .zero, size: screen.size),
                                       panel: panel)
        window.contentView = view

        window.setFrame(screen, display: true)
        window.orderFrontRegardless()

        // Un souffle grave, puis la pluie prend le relais.
        NSSound(named: NSSound.Name("Submarine"))?.play()
        view.start(onCompletion: completion)
    }
}
