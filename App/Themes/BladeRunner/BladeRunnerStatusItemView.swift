//
//  BladeRunnerStatusItemView.swift
//  HAL
//
//  La marque de Tyrell dans la barre de menus : un losange de néon, à côté
//  de la valeur surveillée. Il pulse au repos et brûle en rose quand la
//  ressource approche de la saturation.
//

import AppKit

final class BladeRunnerStatusItemView: StatusItemView {

    private var pulsePhase = 0
    private let markSize: CGFloat = 15

    override var intrinsicContentSize: NSSize {
        let text = readout
        return NSSize(width: markSize + 5 + readoutWidth(text), height: 16)
    }

    override func snapshotDidChange() {
        // Battement lent : la ville ne s'éteint jamais tout à fait.
        pulsePhase = (pulsePhase + 1) % 5
    }

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette
        let tint = critical ? palette.accentSoft : palette.accent

        let rect = NSRect(x: 1, y: (bounds.height - markSize) / 2,
                          width: markSize, height: markSize)
        let diamond = diamondPath(in: rect)
        let inner = diamondPath(in: rect.insetBy(dx: 3.6, dy: 3.6))

        if critical {
            let glow = NSShadow()
            glow.shadowColor = palette.accentSoft.withAlphaComponent(0.95)
            glow.shadowBlurRadius = 4 + 2 * CGFloat(fraction)
            glow.shadowOffset = .zero
            NSGraphicsContext.saveGraphicsState()
            glow.set()
            tint.setStroke()
            diamond.lineWidth = 1.8
            diamond.stroke()
            NSGraphicsContext.restoreGraphicsState()
        }

        tint.withAlphaComponent(pulsePhase == 0 ? 0.65 : 1).setStroke()
        diamond.lineWidth = 1.5
        diamond.stroke()

        tint.withAlphaComponent(critical ? 0.55 : 0.28).setFill()
        inner.fill()

        // La pupille du losange.
        tint.setFill()
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 1.4, y: rect.midY - 1.4,
                                    width: 2.8, height: 2.8)).fill()

        let font = readoutFont
        let color = critical ? palette.accentSoft : palette.text
        readout.draw(at: NSPoint(x: markSize + 5,
                                 y: (bounds.height - font.pointSize) / 2),
                     withAttributes: [.font: font, .foregroundColor: color])
    }

    /// Le losange de Tyrell, lisible à quinze pixels.
    private func diamondPath(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.midX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.midY))
        path.line(to: NSPoint(x: rect.midX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.midY))
        path.close()
        return path
    }
}
