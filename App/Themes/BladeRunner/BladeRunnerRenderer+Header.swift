//
//  BladeRunnerRenderer+Header.swift
//  HAL
//
//  L'en-tête du panneau Blade Runner : titre, plaque, date, séparé du
//  renderer principal.
//

import AppKit

@MainActor

extension BladeRunnerRenderer {

    // MARK: - En-tête

    func drawHeader(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let padding = theme.geometry.padding

        // Nom de la corporation, puis le modèle surveillé.
        let title = "TYRELL CORPORATION"
        var titleAttrs = theme.type.attributes(
            15, color: palette.accentSoft, bold: true, kern: 1.4)
        if let glow = theme.type.glow(palette.accentSoft, radius: 6) {
            titleAttrs[.shadow] = glow
        }
        title.draw(at: NSPoint(x: padding, y: 5), withAttributes: titleAttrs)

        let subtitle = "NEXUS 9 · REPLICANT MONITOR"
        let subtitleAttrs = theme.type.attributes(
            8, color: palette.accent, bold: true, kern: 1.5)
        truncated(subtitle, toWidth: view.bounds.width - 128,
                  attributes: subtitleAttrs)
            .draw(at: NSPoint(x: padding, y: 25), withAttributes: subtitleAttrs)

        let time = DateFormatter()
        time.dateFormat = "HH:mm:ss"
        let meta = "\(HostInfo.registry) · LOS ANGELES · \(time.string(from: view.snapshot.date))"
        let metaAttrs = theme.type.attributes(
            7, color: palette.dim, bold: true, kern: 1.1)
        truncated(meta, toWidth: view.bounds.width - 128, attributes: metaAttrs)
            .draw(at: NSPoint(x: padding, y: 40), withAttributes: metaAttrs)

        drawEye(in: view)
    }

    /// L'œil de Tyrell, réduit à un insigne de néon : une amande cyan, un
    /// iris rose, une pupille noire. Il s'ouvre sur la ville.
    private func drawEye(in view: PanelView) {
        let palette = view.theme.palette
        let frame = view.theme.geometry.headerTipRect(in: view.bounds.width)
        let eye = NSRect(x: frame.minX + 6, y: frame.minY + 8,
                         width: frame.width - 12, height: 17)
        let center = NSPoint(x: eye.midX, y: eye.midY)

        palette.accent.withAlphaComponent(0.16).setFill()
        NSBezierPath(ovalIn: eye).fill()

        palette.accent.withAlphaComponent(0.85).setStroke()
        let ring = NSBezierPath(ovalIn: eye)
        ring.lineWidth = 1.1
        ring.stroke()

        palette.accentSoft.withAlphaComponent(0.9).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 4, y: center.y - 4,
                                    width: 8, height: 8)).fill()
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 1.5, y: center.y - 2.5,
                                    width: 3, height: 5)).fill()
        NSColor.white.withAlphaComponent(0.8).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 2.2, y: center.y + 0.6,
                                    width: 1.6, height: 1.2)).fill()

        // Balayage du néon.
        palette.accent.withAlphaComponent(0.5).setStroke()
        let sweep = NSBezierPath()
        sweep.move(to: NSPoint(x: eye.minX + 5, y: center.y + 1))
        sweep.line(to: NSPoint(x: eye.maxX - 5, y: center.y + 1))
        sweep.lineWidth = 0.5
        sweep.stroke()

        "NEXUS 9".draw(at: NSPoint(x: frame.minX - 2, y: frame.maxY + 1),
                       withAttributes: view.theme.type.attributes(
                        6.5, color: palette.dim, bold: true, kern: 1.4))
    }
}
