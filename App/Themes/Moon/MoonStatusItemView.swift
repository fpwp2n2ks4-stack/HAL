//
//  MoonStatusItemView.swift
//  HAL
//
//  Le petit smiley GERTY dans la barre de menus, tel qu'il apparaît dans
//  Moon : rond bleu, yeux, bouche souriante, sobre.
//

import AppKit

final class MoonStatusItemView: StatusItemView {

    private var blinkPhase = 0
    private let faceSize: CGFloat = 14

    override var intrinsicContentSize: NSSize {
        let text = readout
        return NSSize(width: faceSize + 5 + readoutWidth(text), height: 16)
    }

    override func snapshotDidChange() {
        // Clignement très occasionnel.
        blinkPhase = (blinkPhase + 1) % 16
    }

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette

        let rect = NSRect(x: 1, y: (bounds.height - faceSize) / 2,
                          width: faceSize, height: faceSize)
        let face = critical ? palette.danger : palette.accent

        face.setFill()
        NSBezierPath(ovalIn: rect).fill()

        if blinkPhase < 14 {
            NSColor.black.withAlphaComponent(0.9).setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.minX + 4, y: rect.minY + 4,
                                        width: 2.8, height: 2.8)).fill()
            NSBezierPath(ovalIn: NSRect(x: rect.minX + 8, y: rect.minY + 4,
                                        width: 2.8, height: 2.8)).fill()

            NSColor.black.withAlphaComponent(0.9).setStroke()
            let smile = NSBezierPath()
            smile.move(to: NSPoint(x: rect.minX + 4, y: rect.minY + 9))
            smile.curve(to: NSPoint(x: rect.minX + 11, y: rect.minY + 9),
                        controlPoint1: NSPoint(x: rect.minX + 5, y: rect.minY + 10),
                        controlPoint2: NSPoint(x: rect.minX + 10, y: rect.minY + 10))
            smile.lineWidth = 1.0
            smile.stroke()
        } else {
            NSColor.black.withAlphaComponent(0.9).setStroke()
            NSBezierPath(rect: NSRect(x: rect.minX + 4, y: rect.minY + 5,
                                      width: 2.2, height: 0.6)).stroke()
            NSBezierPath(rect: NSRect(x: rect.minX + 8, y: rect.minY + 5,
                                      width: 2.2, height: 0.6)).stroke()
        }

        let text = readout
        let color = critical ? palette.danger : NSColor.labelColor
        let font = readoutFont
        text.draw(at: NSPoint(x: faceSize + 5, y: (bounds.height - font.pointSize) / 2),
                  withAttributes: [.font: font, .foregroundColor: color])
    }
}
