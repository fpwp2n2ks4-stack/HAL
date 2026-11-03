//
//  LCARSStatusItemView.swift
//  HAL
//
//  L'insigne de la Fédération dans la barre de menus, à côté de la valeur
//  du système surveillé. L'insigne pulse doucement au repos et passe au
//  rouge d'alerte quand la ressource approche de la saturation.
//

import AppKit

final class LCARSStatusItemView: StatusItemView {

    private var pulsePhase = 0
    private let badgeSize: CGFloat = 15

    override var intrinsicContentSize: NSSize {
        let text = readout
        return NSSize(width: badgeSize + 5 + readoutWidth(text), height: 16)
    }

    override func snapshotDidChange() {
        // Battement : l'insigne ne bouge qu'entre deux relevés, ce qui
        // suffit à le faire vivre sans timer supplémentaire.
        pulsePhase = (pulsePhase + 1) % 4
    }

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette
        let tint = critical ? palette.danger : palette.accent

        // --- Insigne ---
        let rect = NSRect(x: 1, y: (bounds.height - badgeSize) / 2,
                          width: badgeSize, height: badgeSize)
        let delta = deltaPath(in: rect)

        // Le halo n'apparaît qu'en alerte : au repos, un insigne de la
        // Fédération ne fait pas de bruit visuel.
        if critical {
            let glow = NSShadow()
            glow.shadowColor = palette.danger.withAlphaComponent(0.9)
            glow.shadowBlurRadius = 4 + 2 * CGFloat(fraction)
            glow.shadowOffset = .zero
            NSGraphicsContext.saveGraphicsState()
            glow.set()
            tint.setStroke()
            delta.lineWidth = 2
            delta.stroke()
            NSGraphicsContext.restoreGraphicsState()
        }

        tint.withAlphaComponent(pulsePhase == 0 ? 0.75 : 1).setStroke()
        delta.lineWidth = 2
        delta.stroke()

        // --- Valeur ---
        let font = readoutFont
        let color = critical ? palette.danger : palette.text
        readout.draw(at: NSPoint(x: badgeSize + 5, y: (bounds.height - font.pointSize) / 2),
                     withAttributes: [.font: font, .foregroundColor: color])
    }

    /// Le delta de la Fédération, réduit à une silhouette lisible à 15 px :
    /// pointe en haut, épaules franches, encoche au centre de la base.
    private func deltaPath(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.midX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX - 0.5, y: rect.minY + 1))
        path.line(to: NSPoint(x: rect.midX + 2.6, y: rect.minY + 3.4))
        path.line(to: NSPoint(x: rect.midX, y: rect.minY + 2.0))
        path.line(to: NSPoint(x: rect.midX - 2.6, y: rect.minY + 3.4))
        path.line(to: NSPoint(x: rect.minX + 0.5, y: rect.minY + 1))
        path.close()
        return path
    }
}
