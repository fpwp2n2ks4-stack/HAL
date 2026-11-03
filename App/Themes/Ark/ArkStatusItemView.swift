//
//  ArkStatusItemView.swift
//  HAL
//
//  L'écusson d'Ark One dans la barre de menus : un hexagone de coque, un
//  vecteur de mission et la valeur surveillée. Il pulse doucement au repos,
//  et vire à l'ambre quand la ressource sature.
//

import AppKit

final class ArkStatusItemView: StatusItemView {

    private var pulsePhase = 0
    private let badgeSize: CGFloat = 15

    override var intrinsicContentSize: NSSize {
        NSSize(width: badgeSize + 5 + readoutWidth(readout), height: 16)
    }

    override func snapshotDidChange() {
        // Battement lent : la console respire avec la télémétrie.
        pulsePhase = (pulsePhase + 1) % 5
    }

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette
        let tint = critical ? palette.warning : palette.accent

        let rect = NSRect(x: 1, y: (bounds.height - badgeSize) / 2,
                          width: badgeSize, height: badgeSize)
        let hexagon = hexagonPath(in: rect)

        if critical {
            let glow = NSShadow()
            glow.shadowColor = palette.warning.withAlphaComponent(0.9)
            glow.shadowBlurRadius = 4 + 2 * CGFloat(fraction)
            glow.shadowOffset = .zero
            NSGraphicsContext.saveGraphicsState()
            glow.set()
            tint.setStroke()
            hexagon.lineWidth = 1.8
            hexagon.stroke()
            NSGraphicsContext.restoreGraphicsState()
        }

        tint.withAlphaComponent(pulsePhase == 0 ? 0.65 : 1).setStroke()
        hexagon.lineWidth = 1.4
        hexagon.stroke()

        // Le vecteur de mission, du centre vers l'extérieur.
        let vector = NSBezierPath()
        vector.move(to: NSPoint(x: rect.minX + 4.2, y: rect.midY + 2.6))
        vector.line(to: NSPoint(x: rect.maxX - 4.2, y: rect.midY - 2.6))
        tint.withAlphaComponent(critical ? 0.95 : 0.7).setStroke()
        vector.lineWidth = 1
        vector.stroke()

        tint.setFill()
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 1.2, y: rect.midY - 1.2,
                                    width: 2.4, height: 2.4)).fill()

        let font = readoutFont
        let color = critical ? palette.warning : palette.text
        readout.draw(at: NSPoint(x: badgeSize + 5,
                                 y: (bounds.height - font.pointSize) / 2),
                     withAttributes: [.font: font, .foregroundColor: color])
    }

    /// Hexagone de coque, lisible à quinze pixels.
    private func hexagonPath(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.midX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.midY + rect.height * 0.24))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.midY - rect.height * 0.24))
        path.line(to: NSPoint(x: rect.midX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX + 1, y: rect.midY - rect.height * 0.24))
        path.line(to: NSPoint(x: rect.minX + 1, y: rect.midY + rect.height * 0.24))
        path.close()
        return path
    }
}
