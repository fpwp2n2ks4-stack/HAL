//
//  StarTrekExitScreen.swift
//  HAL
//
//  La mise hors service. Au quit, la console gelée sur son dernier relevé
//  s'affiche plein écran, puis s'éteint bloc par bloc, du bas vers le haut.
//  Alors seulement la plaque de décommissionnement apparaît : nom du
//  vaisseau, immatriculation, date stellaire. Les segments LCARS s'éteignent
//  un à un, dans un ordre imprévisible, puis la console tombe en veille.
//

import AppKit

final class StarTrekExitView: NSView {

    /// Console figée, rendue une fois pour toutes.
    private let cockpit: NSImage
    private let cockpitRect: NSRect

    /// Zones à éteindre, déjà converties en coordonnées de la vue, dans
    /// l'ordre d'extinction.
    private let screenRects: [NSRect]

    private let theme: ThemeDefinition
    private let stardate: String

    /// Ordre aléatoire de disparition des segments de la plaque.
    private let segmentDeathOrder: [Int]

    private var start: Date?
    private var animationTask: Task<Void, Never>?

    private static let cascadeDuration: TimeInterval = 2.2
    private static let plateDuration: TimeInterval = 1.9
    private static let standbyDuration: TimeInterval = 1.2
    private static let totalDuration: TimeInterval =
        cascadeDuration + plateDuration + standbyDuration

    private static let segmentCount = 14

    override var isOpaque: Bool { true }

    /// La vue est dessinée de haut en bas, comme le panneau : les zones
    /// d'extinction converties depuis `dashboardScreenRects` tombent ainsi
    /// au bon endroit.
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
        stardate = Stardate.string(for: panel.snapshot.date)

        var converted: [NSRect] = []
        for rect in panel.dashboardScreenRects {
            let convertedX = origin.x + rect.minX * scale
            let convertedY = origin.y + rect.minY * scale
            converted.append(NSRect(x: convertedX, y: convertedY,
                                    width: rect.width * scale,
                                    height: rect.height * scale))
        }
        screenRects = converted
        segmentDeathOrder = (0..<Self.segmentCount).shuffled()
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    // MARK: - Rendu de la console

    /// Rend le panneau dans une image, à la définition de l'écran : dernier
    /// relevé du vaisseau.
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
        drawCockpit(cascade: elapsed / Self.cascadeDuration)

        let plateProgress = (elapsed - Self.cascadeDuration) / Self.plateDuration
        if plateProgress > 0 {
            drawDecommission(progress: min(1, plateProgress))
        }

        let standbyProgress = (elapsed - Self.cascadeDuration - Self.plateDuration)
            / Self.standbyDuration
        if standbyProgress > 0 {
            drawStandby(progress: min(1, standbyProgress))
        }
    }

    /// La console, bloc par bloc : chaque zone tombe dans le noir à son
    /// tour. Les systèmes s'éteignent du bas vers le haut, l'en-tête en
    /// dernier.
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

        if cascade >= 1 {
            NSColor.black.setFill()
            cockpitRect.fill()
        }
    }

    /// La plaque de décommissionnement : bandeau orange, immatriculation,
    /// puis les segments qui s'éteignent un à un.
    private func drawDecommission(progress: Double) {
        let palette = theme.palette
        let alpha = min(1, progress * 5)
        let width = min(bounds.width * 0.58, 720)
        let height: CGFloat = 214
        let origin = NSPoint(x: (bounds.width - width) / 2,
                             y: (bounds.height - height) / 2)
        let plate = NSRect(x: origin.x, y: origin.y, width: width, height: height)

        palette.accentSoft.withAlphaComponent(alpha).setFill()
        plate.fill()

        drawShipBanner(plate: plate, alpha: alpha, width: width)

        // Corps sombre.
        let bannerHeight: CGFloat = 48
        let body = NSRect(x: plate.minX, y: plate.minY + bannerHeight,
                          width: plate.width, height: plate.height - bannerHeight)
        palette.background.withAlphaComponent(alpha).setFill()
        body.fill()

        let titleFont = theme.type.font(min(44, width / 15), bold: true)
        let title = theme.copy.farewell
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: palette.accentSoft.withAlphaComponent(alpha),
            .kern: 2.0
        ]
        let titleWidth = title.size(withAttributes: titleAttrs).width
        title.draw(at: NSPoint(x: plate.midX - titleWidth / 2, y: plate.minY + 64),
                   withAttributes: titleAttrs)

        let stardateFont = theme.type.font(11, bold: true)
        let stardateText = "STARDATE \(stardate)"
        let stardateAttrs: [NSAttributedString.Key: Any] = [
            .font: stardateFont,
            .foregroundColor: palette.dim.withAlphaComponent(alpha),
            .kern: 1.4
        ]
        let stardateWidth = stardateText.size(withAttributes: stardateAttrs).width
        stardateText.draw(at: NSPoint(x: plate.midX - stardateWidth / 2,
                                      y: plate.minY + 118),
                          withAttributes: stardateAttrs)

        drawSegments(in: plate, progress: progress, alpha: alpha)
    }

    /// Les segments LCARS de la plaque s'éteignent un à un.
    private func drawSegments(in plate: NSRect, progress: Double, alpha: Double) {
        let count = Self.segmentCount
        let gap: CGFloat = 6
        let inset: CGFloat = 22
        let segmentWidth = (plate.width - inset * 2 - gap * CGFloat(count - 1)) / CGFloat(count)
        let rowY = plate.maxY - 48
        let height: CGFloat = 8

        let palette = theme.palette
        let colors: [NSColor] = [
            palette.accent, palette.accentSoft, LCARSTheme.lilac, LCARSTheme.blue,
            palette.accent, palette.accentSoft
        ]

        let gone = Int(progress * Double(count))
        let dead = Set(segmentDeathOrder.prefix(gone))
        let dying = Set(segmentDeathOrder.prefix(min(count, gone + 1)))

        for index in 0..<count {
            let segmentX = plate.minX + inset + CGFloat(index) * (segmentWidth + gap)
            let rect = NSRect(x: segmentX, y: rowY, width: segmentWidth, height: height)
            if dead.contains(index) { continue }
            let color = dying.contains(index)
                ? colors[index % colors.count].withAlphaComponent(0.25 * alpha)
                : colors[index % colors.count].withAlphaComponent(alpha)
            color.setFill()
            NSBezierPath(rect: rect).fill()
        }
    }

    /// « STANDBY » : la console veille, puis s'éteint pour de bon.
    private func drawStandby(progress: Double) {
        let font = theme.type.font(26, bold: true)
        let text = "STANDBY"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: 6.0
        ]
        let width = text.size(withAttributes: attrs).width
        let blink = 0.35 + 0.65 * abs(sin(progress * .pi * 2))
        let alpha = min(1, (1 - progress) * 2.2) * blink
        text.draw(at: NSPoint(x: (bounds.width - width) / 2,
                              y: (bounds.height - 26) / 2),
                  withAttributes: [
                    .font: font,
                    .foregroundColor: theme.palette.warning.withAlphaComponent(alpha),
                    .kern: 6.0
                  ])
    }

    /// Le bandeau supérieur de la plaque : le nom du vaisseau, l'immatriculation.
    private func drawShipBanner(plate: NSRect, alpha: CGFloat, width: CGFloat) {
        let palette = theme.palette
        let bar = NSRect(x: plate.minX, y: plate.minY, width: plate.width, height: 48)
        palette.accent.withAlphaComponent(alpha).setFill()
        bar.fill()

        let nameFont = theme.type.font(min(30, width / 24), bold: true)
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: palette.background.withAlphaComponent(alpha),
            .kern: 0.6
        ]
        let registryFont = theme.type.font(16, bold: true)
        let registry = HostInfo.registry
        let registryAttrs: [NSAttributedString.Key: Any] = [
            .font: registryFont,
            .foregroundColor: palette.background.withAlphaComponent(alpha),
            .kern: 1.0
        ]
        let registryWidth = registry.size(withAttributes: registryAttrs).width

        /// Coupe le nom du vaisseau s'il menace l'immatriculation.
        func fitted(_ text: String, to maxWidth: CGFloat) -> String {
            guard text.size(withAttributes: nameAttrs).width > maxWidth else { return text }
            let ellipsis = "…"
            let ellipsisWidth = ellipsis.size(withAttributes: nameAttrs).width
            var cut = text
            while !cut.isEmpty,
                  cut.size(withAttributes: nameAttrs).width + ellipsisWidth > maxWidth {
                cut.removeLast()
            }
            return cut + ellipsis
        }

        let name = fitted("U.S.S. \(HostInfo.shipName)",
                          to: plate.width - 44 - registryWidth - 20)
        name.draw(at: NSPoint(x: plate.minX + 22, y: plate.minY + 9),
                  withAttributes: nameAttrs)
        registry.draw(at: NSPoint(x: plate.maxX - 22 - registryWidth, y: plate.minY + 16),
                      withAttributes: registryAttrs)
    }
}

enum StarTrekExitScreen {

    /// Affiche la console, la laisse s'éteindre, puis termine l'application.
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

        let view = StarTrekExitView(frame: NSRect(origin: .zero, size: screen.size),
                                    panel: panel)
        window.contentView = view

        window.setFrame(screen, display: true)
        window.orderFrontRegardless()

        NSSound(named: NSSound.Name("Tink"))?.play()
        view.start(onCompletion: completion)
    }
}
