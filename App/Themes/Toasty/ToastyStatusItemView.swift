//
//  ToastyStatusItemView.swift
//  HAL
//
//  L'œil Cylon dans la barre de menus : une lentille chromée étroite, un
//  seul segment rouge allumé, qui fait l'aller-retour à chaque relevé. Le
//  grille-pain veille. En critique, l'œil s'allume tout entier : c'est
//  comme ça que la flotte sait qu'il est temps de sauter.
//

import AppKit

final class ToastyStatusItemView: StatusItemView {

    private var sweep = 0
    private var forward = true
    private let eyeWidth: CGFloat = 20
    private let eyeHeight: CGFloat = 9

    override var intrinsicContentSize: NSSize {
        let text = readout
        return NSSize(width: eyeWidth + 5 + readoutWidth(text), height: 16)
    }

    override func snapshotDidChange() {
        // Un cran par relevé, avec le retour : 0 1 2 3 4 3 2 1 0…
        if forward {
            sweep += 1
            if sweep >= 4 { forward = false }
        } else {
            sweep -= 1
            if sweep <= 0 { forward = true }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette

        let rect = NSRect(x: 1, y: (bounds.height - eyeHeight) / 2,
                          width: eyeWidth, height: eyeHeight)

        // Lentille chromée.
        let chrome = NSColor(srgbRed: 0.588, green: 0.561, blue: 0.518, alpha: 1)
        chrome.setFill()
        NSBezierPath(roundedRect: rect, xRadius: rect.height / 2,
                      yRadius: rect.height / 2).fill()

        let inner = rect.insetBy(dx: 1.5, dy: 1.5)
        NSColor.black.withAlphaComponent(0.55).setFill()
        NSBezierPath(roundedRect: inner, xRadius: inner.height / 2,
                      yRadius: inner.height / 2).fill()

        // Segments : tous allumés en critique, un seul balayant sinon.
        let segments = 5
        let gap: CGFloat = 1
        let width = (inner.width - gap * CGFloat(segments - 1)) / CGFloat(segments)
        let lit = sweep % segments
        let tint = critical ? palette.danger : palette.accent

        for index in 0..<segments {
            let segment = NSRect(x: inner.minX + CGFloat(index) * (width + gap),
                                 y: inner.minY,
                                 width: width,
                                 height: inner.height)
            let isLit = critical || index == lit
            tint.withAlphaComponent(isLit ? 0.95 : 0.18).setFill()
            NSBezierPath(rect: segment).fill()
        }

        let text = readout
        let color = critical ? palette.danger : NSColor.labelColor
        let font = readoutFont
        text.draw(at: NSPoint(x: eyeWidth + 5, y: (bounds.height - font.pointSize) / 2),
                  withAttributes: [.font: font, .foregroundColor: color])
    }
}
