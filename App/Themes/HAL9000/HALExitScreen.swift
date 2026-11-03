//
//  GoodbyeScreen.swift
//  HAL
//
//  La mort de HAL. Au quit, le cockpit gelé sur son dernier relevé
//  s'affiche plein écran, puis s'éteint écran par écran comme les
//  salles-cerveaux du Discovery One : chaque zone du tableau de bord
//  tombe dans le noir l'une après l'autre, du bas vers le haut, l'œil
//  de l'en-tête en dernier. Alors seulement « GOOD BYE » apparaît, et
//  ses lettres perdent la vie à leur tour, dans un ordre imprévisible,
//  jusqu'au noir absolu — puis le processus sort.
//

import AppKit

final class GoodbyeView: NSView {

    /// Cockpit figé, rendu une fois pour toutes : le tube est mort, il ne
    /// doit plus battre au rythme des relevés.
    private let cockpit: NSImage
    private let cockpitRect: NSRect

    /// Zones à éteindre, déjà converties en coordonnées de la vue, dans
    /// l'ordre d'extinction.
    private let screenRects: [NSRect]

    private let theme: ThemeDefinition

    /// Ordre aléatoire de disparition des lettres de « GOOD BYE ».
    private let letterDeathOrder: [Int]

    private var start: Date?
    private var animationTask: Task<Void, Never>?

    // Durées des deux actes, en secondes.
    private static let cascadeDuration: TimeInterval = 2.4
    private static let farewellDuration: TimeInterval = 1.8
    private static let totalDuration: TimeInterval =
        cascadeDuration + farewellDuration

    override var isOpaque: Bool { true }
    override var isFlipped: Bool { true }

    init(frame frameRect: NSRect, panel: PanelView) {
        // Le cockpit occupe l'essentiel de l'écran, avec une marge pour
        // respirer : la mort est intime, pas une affiche.
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

        var converted: [NSRect] = []
        for rect in panel.dashboardScreenRects {
            let convertedX = origin.x + rect.minX * scale
            let convertedY = origin.y + rect.minY * scale
            converted.append(NSRect(x: convertedX, y: convertedY,
                                    width: rect.width * scale,
                                    height: rect.height * scale))
        }
        screenRects = converted
        letterDeathOrder = (0..<panel.theme.copy.farewell.count).shuffled()
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    // MARK: - Rendu du cockpit

    /// Rend le panneau dans une image, à la définition de l'écran :
    /// dernier souffle du tableau de bord.
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

    /// Lance la séquence, puis appelle `completion` pour quitter.
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
        drawCockpit(cascade: elapsed / Self.cascadeDuration)

        let farewellProgress = (elapsed - Self.cascadeDuration) / Self.farewellDuration
        if farewellProgress > 0 {
            drawFarewell(hiding: min(1, farewellProgress))
        }

        drawScanlines()
    }

    /// Le cockpit, écran par écran : chaque zone tombe dans le noir à son
    /// tour, et celle qui meurt crépite avant de céder.
    private func drawCockpit(cascade: Double) {
        cockpit.draw(in: cockpitRect)

        guard cascade > 0 else { return }
        let count = Double(screenRects.count)

        for (index, rect) in screenRects.enumerated() {
            let death = cascade * count - Double(index)
            guard death > 0 else { continue }
            let darkness = min(1, death)
            let flicker = darkness < 1 ? Double.random(in: 0.6...1.0) : 1.0
            NSColor.black.withAlphaComponent(darkness * flicker).setFill()
            NSBezierPath(rect: rect).fill()
        }

        // Toutes les zones éteintes : le noir gagne le cockpit entier.
        if cascade >= 1 {
            NSColor.black.setFill()
            cockpitRect.fill()
        }
    }

    /// « GOOD BYE » : les lettres s'éteignent une à une, dans un ordre
    /// imprévisible, jusqu'à ce que l'écran soit vide.
    private func drawFarewell(hiding progress: Double) {
        let font = theme.type.font(72, bold: true)
        let farewell = theme.copy.farewell
        let letters = farewell.map(String.init)
        let widths = letters.map { $0.size(withAttributes: [.font: font]).width }
        let totalWidth = widths.reduce(0, +)

        let dead = Int(progress * Double(letters.count))
        let gone = Set(letterDeathOrder.prefix(dead))
        // Celle qui meurt à cet instant tremble avant de s'éteindre.
        let dying = Set(letterDeathOrder.prefix(min(letters.count, dead + 1)))

        var letterX = (bounds.width - totalWidth) / 2
        let textY = (bounds.height - font.pointSize) / 2

        for (index, letter) in letters.enumerated() {
            defer { letterX += widths[index] }
            guard !gone.contains(index) else { continue }

            let alpha: CGFloat = dying.contains(index)
                ? CGFloat.random(in: 0.2...1.0)
                : 1
            var attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white.withAlphaComponent(alpha)
            ]
            if let glow = theme.type.glow(NSColor.white, radius: 12) {
                attrs[.shadow] = glow
            }
            letter.draw(at: NSPoint(x: letterX, y: textY), withAttributes: attrs)
        }
    }

    /// Scanlines : l'adieu passe aussi par le tube.
    private func drawScanlines() {
        NSColor.black.withAlphaComponent(0.25).setFill()
        var scanlineY: CGFloat = 0
        while scanlineY < bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: scanlineY,
                                      width: bounds.width, height: 1)).fill()
            scanlineY += 3
        }
    }
}

enum GoodbyeScreen {

    /// Affiche le panneau fourni, le laisse mourir, puis termine l'app.
    ///
    /// La fenêtre reste référencée par AppKit tant qu'elle est à l'écran ;
    /// elle doit être visible **avant** l'activation de l'app, sinon elle
    /// passe derrière les autres fenêtres.
    @MainActor static func show(panel: PanelView, then completion: @escaping () -> Void) {
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

        let view = GoodbyeView(frame: NSRect(origin: .zero, size: screen.size),
                               panel: panel)
        window.contentView = view

        // Cadré sur l'écran principal, sans fondu : un tube cathodique ne
        // fait pas de fondu, il s'allume — et il s'éteint d'un coup.
        window.setFrame(screen, display: true)
        window.orderFrontRegardless()

        NSSound.beep()
        view.start(onCompletion: completion)
    }
}
