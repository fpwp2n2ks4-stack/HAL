//
//  MoonExitScreen.swift
//  HAL
//
//  La fin à Sarang. Le panneau se fige, les écrans s'éteignent dans le
//  silence, et « GOODNIGHT, SAM. » s'affiche avec une politesse glaciaire,
//  avant que tout ne devienne noir.
//

import AppKit

final class MoonExitView: NSView {

    private let cockpit: NSImage
    private let cockpitRect: NSRect
    private let screenRects: [NSRect]
    private let theme: ThemeDefinition
    private let farewell: String

    private var start: Date?
    private var animationTask: Task<Void, Never>?

    private static let cascadeDuration: TimeInterval = 2.0
    private static let farewellDuration: TimeInterval = 1.6
    private static let holdDuration: TimeInterval = 0.6
    private static let fadeDuration: TimeInterval = 0.8
    private static let totalDuration: TimeInterval =
        cascadeDuration + farewellDuration + holdDuration + fadeDuration

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

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        let elapsed = Date().timeIntervalSince(start ?? Date())
        let cascade = min(1, elapsed / Self.cascadeDuration)
        drawCockpit(cascade: cascade)

        let farewellStart = Self.cascadeDuration
        if elapsed > farewellStart {
            let progress = min(1, (elapsed - farewellStart) / Self.farewellDuration)
            drawFarewell(progress: progress)
        }

        let fadeStart = Self.cascadeDuration + Self.farewellDuration + Self.holdDuration
        if elapsed > fadeStart {
            let progress = min(1, (elapsed - fadeStart) / Self.fadeDuration)
            NSColor.black.withAlphaComponent(progress).setFill()
            bounds.fill()
        }

        drawScanlines()
    }

    private func drawCockpit(cascade: Double) {
        cockpit.draw(in: cockpitRect)

        guard cascade > 0 else { return }
        let count = Double(screenRects.count)

        for (index, rect) in screenRects.enumerated() {
            let death = cascade * count - Double(index)
            guard death > 0 else { continue }
            let darkness = min(1, death)
            let flicker = darkness < 1 ? Double.random(in: 0.85...1.0) : 1.0
            NSColor.black.withAlphaComponent(darkness * flicker).setFill()
            NSBezierPath(rect: rect).fill()
        }

        if cascade >= 1 {
            NSColor.black.setFill()
            cockpitRect.fill()
        }
    }

    private func drawFarewell(progress: Double) {
        let font = NSFont(name: "Helvetica-Bold", size: 44)
            ?? NSFont.boldSystemFont(ofSize: 44)
        let alpha = min(1, progress * 1.2)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(alpha),
            .kern: 1.0
        ]
        let width = farewell.size(withAttributes: attrs).width
        farewell.draw(at: NSPoint(x: (bounds.width - width) / 2,
                                  y: (bounds.height - font.pointSize) / 2),
                      withAttributes: attrs)
    }

    private func drawScanlines() {
        NSColor.black.withAlphaComponent(0.16).setFill()
        var lineY: CGFloat = 0
        while lineY < bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: lineY,
                                      width: bounds.width, height: 1)).fill()
            lineY += 4
        }
    }
}

enum MoonExitScreen {

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

        let view = MoonExitView(frame: NSRect(origin: .zero, size: screen.size),
                                panel: panel)
        window.contentView = view

        window.setFrame(screen, display: true)
        window.orderFrontRegardless()

        view.start(onCompletion: completion)
    }
}
