//
//  WarGamesStatusItemView.swift
//  HAL
//
//  Le terminal WOPR dans la barre de menus : un petit écran CRT, une invite
//  et un curseur qui clignote, à côté de la valeur surveillée. Quand la
//  ressource sature, l'écran passe au rouge et l'invite devient « !! ».
//

import AppKit

final class WarGamesStatusItemView: StatusItemView {

    private var blinkPhase = 0
    private let crtWidth: CGFloat = 17
    private let crtHeight: CGFloat = 14

    override var intrinsicContentSize: NSSize {
        let text = readout
        return NSSize(width: crtWidth + 5 + readoutWidth(text), height: 16)
    }

    override func snapshotDidChange() {
        // Le curseur bat entre deux relevés, sans timer supplémentaire.
        blinkPhase = (blinkPhase + 1) % 4
    }

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette
        let tint = critical ? palette.danger : palette.accent

        let body = NSRect(x: 1, y: (bounds.height - crtHeight) / 2 + 1,
                          width: crtWidth, height: crtHeight - 3)

        // Coque du moniteur, puis écran.
        palette.panelDeep.setFill()
        NSBezierPath(roundedRect: body, xRadius: 2, yRadius: 2).fill()
        tint.withAlphaComponent(0.9).setStroke()
        let shell = NSBezierPath(roundedRect: body, xRadius: 2, yRadius: 2)
        shell.lineWidth = 1
        shell.stroke()

        let screen = body.insetBy(dx: 1.8, dy: 1.8)
        palette.screen.setFill()
        NSBezierPath(rect: screen).fill()

        if critical {
            glowDanger(screen: screen)
        }

        // Invite et curseur.
        let prompt = critical ? "!" : ">"
        let font = theme.type.font(6, bold: true)
        prompt.draw(at: NSPoint(x: screen.minX + 1, y: screen.minY + 1),
                    withAttributes: [.font: font, .foregroundColor: tint])
        if blinkPhase != 0 || critical {
            tint.setFill()
            NSBezierPath(rect: NSRect(x: screen.minX + 6, y: screen.minY + 1.5,
                                      width: 3.5, height: 5)).fill()
        }

        // Pied du moniteur.
        tint.withAlphaComponent(0.6).setFill()
        NSBezierPath(rect: NSRect(x: body.midX - 3.5, y: body.maxY,
                                  width: 7, height: 1.2)).fill()
        NSBezierPath(rect: NSRect(x: body.midX - 6, y: body.maxY + 1.2,
                                  width: 12, height: 1)).fill()

        if critical {
            glowDangerRing(screen: screen)
        }

        let readoutAttrs: [NSAttributedString.Key: Any] = [
            .font: readoutFont,
            .foregroundColor: critical ? palette.danger : palette.text
        ]
        readout.draw(at: NSPoint(x: crtWidth + 5,
                                 y: (bounds.height - readoutFont.pointSize) / 2),
                     withAttributes: readoutAttrs)
    }

    /// En critique, l'écran du WOPR s'illumine : remplissage rouge et
    /// halo pulsé à rythme de charge.
    private func glowDanger(screen: NSRect) {
        let glow = NSShadow()
        glow.shadowColor = theme.palette.danger.withAlphaComponent(0.95)
        glow.shadowBlurRadius = 3.5 + 2 * CGFloat(fraction)
        glow.shadowOffset = .zero
        NSGraphicsContext.saveGraphicsState()
        glow.set()
        theme.palette.danger.withAlphaComponent(0.22).setFill()
        NSBezierPath(rect: screen).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    /// En critique, un anneau rouge cerne l'écran : la défcon se voit
    /// même sans lire le chiffre.
    private func glowDangerRing(screen: NSRect) {
        let glow = NSShadow()
        glow.shadowColor = theme.palette.danger.withAlphaComponent(0.95)
        glow.shadowBlurRadius = 3.5 + 2 * CGFloat(fraction)
        glow.shadowOffset = .zero
        NSGraphicsContext.saveGraphicsState()
        glow.set()
        theme.palette.danger.setStroke()
        let ring = NSBezierPath(rect: screen)
        ring.lineWidth = 1
        ring.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
}
