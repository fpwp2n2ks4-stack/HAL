//
//  HALStatusItemView.swift
//  HAL
//
//  L'œil rouge de HAL dans la barre de menus, à côté de la métrique
//  choisie. L'œil « regarde » : la pupille et le halo suivent la charge,
//  l'iris passe au rouge intense quand la ressource approche de la
//  saturation.
//

import AppKit

final class HALStatusItemView: StatusItemView {

    private var blinkPhase = 0
    private let eyeSize: CGFloat = 15

    override var intrinsicContentSize: NSSize {
        let text = readout
        // Sans valeur, l'œil doit occuper toute la largeur pour être
        // réellement centré sous la caméra.
        if text.isEmpty {
            return NSSize(width: eyeSize + 2, height: 16)
        }
        return NSSize(width: eyeSize + 5 + readoutWidth(text), height: 16)
    }

    override func snapshotDidChange() {
        // Clignement périodique : la paupière ne bouge qu'entre deux
        // relevés, ce qui suffit à donner la vie sans timer supplémentaire.
        blinkPhase = (blinkPhase + 1) % 6
    }

    override func draw(_ dirtyRect: NSRect) {
        let load = fraction
        let critical = isCritical

        // --- Œil ---
        let center = NSPoint(x: eyeSize / 2 + 1, y: bounds.midY)

        // Pupille concentrique à l'iris, qui se dilate avec la charge.
        let dilation = 0.34 + 0.26 * min(1, load)
        let pupilWidth = eyeSize * dilation
        let pupilHeight = eyeSize * dilation
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - pupilWidth / 2,
                                    y: center.y - pupilHeight / 2,
                                    width: pupilWidth, height: pupilHeight)).fill()

        let iris = critical
            ? NSColor(srgbRed: 1.0, green: 0.15, blue: 0.10, alpha: 1)
            : NSColor(srgbRed: 0.65, green: 0.05, blue: 0.05, alpha: 1)
        let ring = NSBezierPath(ovalIn: NSRect(x: center.x - eyeSize / 2,
                                               y: center.y - eyeSize / 2,
                                               width: eyeSize, height: eyeSize))
        iris.setStroke()
        ring.lineWidth = 2.5
        ring.stroke()

        if critical {
            let shadow = NSShadow()
            shadow.shadowColor = NSColor(srgbRed: 1, green: 0.1, blue: 0.1, alpha: 0.9)
            shadow.shadowBlurRadius = 4 + 3 * CGFloat(load)
            shadow.shadowOffset = .zero
            NSGraphicsContext.saveGraphicsState()
            shadow.set()
            iris.setFill()
            NSBezierPath(ovalIn: NSRect(x: center.x - 2, y: center.y - 2,
                                        width: 4, height: 4)).fill()
            NSGraphicsContext.restoreGraphicsState()
        }

        // Reflet spéculaire, absent pendant le clignement.
        if blinkPhase != 0 {
            NSColor.white.withAlphaComponent(0.85).setFill()
            NSBezierPath(ovalIn: NSRect(x: center.x - eyeSize * 0.28,
                                        y: center.y + eyeSize * 0.08,
                                        width: 3, height: 2.4)).fill()
        }

        // --- Valeur ---
        let text = readout
        let color = critical ? NSColor.systemRed : NSColor.labelColor
        let font = readoutFont
        text.draw(at: NSPoint(x: eyeSize + 5, y: (bounds.height - font.pointSize) / 2),
                  withAttributes: [.font: font, .foregroundColor: color])
    }
}
