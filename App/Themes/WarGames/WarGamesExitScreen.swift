//
//  WarGamesExitScreen.swift
//  HAL
//
//  La fin de la partie. Au quit, le terminal gelé s'affiche plein écran,
//  ses écrans s'éteignent un à un, puis « GAME OVER » s'imprime caractère
//  par caractère. Joshua conclut, le tube se replie en une ligne, puis en
//  un point — et le noir.
//

import AppKit

final class WarGamesExitView: NSView {

    /// Panneau figé, rendu une fois pour toutes : le dernier relevé avant
    /// l'extinction.
    private let cockpit: NSImage
    private let cockpitRect: NSRect

    /// Zones des écrans, converties en coordonnées de la vue, dans l'ordre
    /// d'extinction.
    private let screenRects: [NSRect]

    private let theme: ThemeDefinition
    private let farewell: String

    private var start: Date?
    private var animationTask: Task<Void, Never>?

    private static let cascadeDuration: TimeInterval = 1.5
    private static let typingDuration: TimeInterval = 1.5
    private static let quoteDuration: TimeInterval = 0.9
    private static let holdDuration: TimeInterval = 0.5
    private static let collapseDuration: TimeInterval = 0.7

    private static let totalDuration: TimeInterval =
        cascadeDuration + typingDuration + quoteDuration
            + holdDuration + collapseDuration

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
            try? await Task.sleep(nanoseconds: UInt64((Self.totalDuration + 0.3) * 1_000_000_000))
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

        let terminal = elapsed - Self.cascadeDuration
        if terminal > 0 {
            drawTerminal(elapsed: terminal)
        }

        drawScanlines()
    }

    /// Le terminal s'éteint écran par écran, du bas vers le haut.
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

    /// « GAME OVER » s'imprime, puis la seule phrase qui compte.
    private func drawTerminal(elapsed: TimeInterval) {
        let palette = theme.palette
        let font = theme.type.font(62, bold: true)

        let collapseStart = Self.typingDuration + Self.quoteDuration
            + Self.holdDuration
        let collapse = (elapsed - collapseStart) / Self.collapseDuration

        if collapse > 0 {
            drawCollapse(progress: min(1, collapse))
            return
        }

        // Les caractères apparaissent un par un, comme sur une imprimante.
        let letters = Array(farewell)
        let typing = min(1, elapsed / Self.typingDuration)
        let shown = Int((typing * Double(letters.count)).rounded(.up))
        let text = String(letters.prefix(shown))

        let fullWidth = farewell.size(withAttributes: [.font: font]).width
        let baseX = (bounds.width - fullWidth) / 2
        let baseY = (bounds.height - font.pointSize) / 2

        var attrs = theme.type.attributes(
            62, color: palette.accentSoft, bold: true, kern: 3)
        if let glow = theme.type.glow(palette.accentSoft, radius: 16) {
            attrs[.shadow] = glow
        }
        text.draw(at: NSPoint(x: baseX, y: baseY), withAttributes: attrs)

        // Curseur bloc : il bat tant que la machine écrit.
        let blink = Int(Date().timeIntervalSinceReferenceDate * 2) % 2
        if typing < 1 || blink == 0 {
            let textWidth = text.size(withAttributes: attrs).width
            palette.accent.setFill()
            NSBezierPath(rect: NSRect(x: baseX + textWidth + 8, y: baseY + 6,
                                      width: font.pointSize * 0.5,
                                      height: font.pointSize * 0.75)).fill()
        }

        let caption = "WOPR · NORAD · CHEYENNE MOUNTAIN"
        let captionAttrs = theme.type.attributes(
            9, color: palette.dim, bold: true, kern: 2.2)
        let captionWidth = caption.size(withAttributes: captionAttrs).width
        caption.draw(at: NSPoint(x: (bounds.width - captionWidth) / 2,
                                 y: baseY - 26),
                     withAttributes: captionAttrs)

        // La conclusion n'apparaît qu'une fois la partie terminée.
        let quoteStart = Self.typingDuration
        if elapsed > quoteStart {
            let progress = min(1, (elapsed - quoteStart) / Self.quoteDuration)
            let quote = "“A STRANGE GAME. THE ONLY WINNING MOVE IS NOT TO PLAY.”"
            let quoteAttrs = theme.type.attributes(
                10, color: palette.dim.withAlphaComponent(0.9 * progress),
                bold: true, kern: 0.8)
            let quoteWidth = quote.size(withAttributes: quoteAttrs).width
            quote.draw(at: NSPoint(x: (bounds.width - quoteWidth) / 2,
                                   y: baseY + font.pointSize + 20),
                       withAttributes: quoteAttrs)
        }
    }

    /// Le tube se replie : une ligne de phosphore, puis un point, puis rien.
    private func drawCollapse(progress: Double) {
        let palette = theme.palette
        let centerY = bounds.midY

        guard progress < 1 else { return }

        if progress < 0.68 {
            let fraction = progress / 0.68
            let width = max(2, bounds.width * (1 - fraction))
            let alpha = 0.85 + 0.15 * (1 - fraction)

            let glow = NSShadow()
            glow.shadowColor = palette.accent.withAlphaComponent(0.95)
            glow.shadowBlurRadius = 18
            glow.shadowOffset = .zero

            NSGraphicsContext.saveGraphicsState()
            glow.set()
            palette.accentSoft.withAlphaComponent(alpha).setFill()
            NSBezierPath(rect: NSRect(x: (bounds.width - width) / 2,
                                      y: centerY - 1.2,
                                      width: width, height: 2.4)).fill()
            NSGraphicsContext.restoreGraphicsState()
        } else {
            let fraction = (progress - 0.68) / 0.32
            let radius = max(0.5, 5 * (1 - fraction))
            let alpha = 1 - fraction

            let glow = NSShadow()
            glow.shadowColor = palette.accentSoft.withAlphaComponent(alpha)
            glow.shadowBlurRadius = 22
            glow.shadowOffset = .zero

            NSGraphicsContext.saveGraphicsState()
            glow.set()
            palette.accentSoft.withAlphaComponent(alpha).setFill()
            NSBezierPath(ovalIn: NSRect(x: bounds.midX - radius,
                                        y: centerY - radius,
                                        width: radius * 2,
                                        height: radius * 2)).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
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

enum WarGamesExitScreen {

    /// Affiche le panneau fourni, regarde la partie se terminer, puis quitte.
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

        let view = WarGamesExitView(frame: NSRect(origin: .zero, size: screen.size),
                                    panel: panel)
        window.contentView = view

        window.setFrame(screen, display: true)
        window.orderFrontRegardless()

        NSSound.beep()
        view.start(onCompletion: completion)
    }
}
