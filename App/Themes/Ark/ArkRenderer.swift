//
//  ArkRenderer.swift
//  HAL
//
//  Le dessin de la console Ark One : panneaux biseautés, rails de coque,
//  jauges segmentées, cyan de veille et ambre d'alarme. Une console de
//  vaisseau-colonie, pas un tube cathodique : pas de scanlines lourdes,
//  seulement la trame discrète d'un affichage embarqué.
//

import AppKit

@MainActor

final class ArkRenderer: ThemeRenderer {

    // MARK: - Formes

    /// Panneau à coins coupés : deux biseaux opposés, comme les cloisons
    /// modulaires de l'Ark.
    func chamferedPath(_ rect: NSRect, cut: CGFloat = 5) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX + cut, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - cut))
        path.line(to: NSPoint(x: rect.maxX - cut, y: rect.maxY))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.minX, y: rect.minY + cut))
        path.close()
        return path
    }

    func stroke(_ path: NSBezierPath, _ color: NSColor, width: CGFloat = 1) {
        color.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    // MARK: - Fond

    func drawBackground(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let radius = theme.geometry.cornerRadius

        let shape = NSBezierPath(roundedRect: view.bounds,
                                 xRadius: radius, yRadius: radius)
        if let gradient = NSGradient(starting: palette.panel,
                                     ending: palette.background) {
            gradient.draw(in: shape, angle: -90)
        } else {
            palette.background.setFill()
            shape.fill()
        }

        // Étoiles fixes : la coque regarde le vide, pas un écran de salon.
        drawStarField(in: view)

        // Rails de coque, à gauche et à droite : de petits repères de
        // structure qui donnent l'échelle du vaisseau.
        drawHullRails(in: view)

        stroke(NSBezierPath(roundedRect: view.bounds.insetBy(dx: 0.5, dy: 0.5),
                            xRadius: radius, yRadius: radius),
               palette.bezel.withAlphaComponent(0.85))
    }

    /// Le champ d'étoiles fixes du fond : seize points, en coordonnées
    /// relatives au panneau.
    private func drawStarField(in view: PanelView) {
        let palette = view.theme.palette
        let stars: [Star] = [
            Star(atX: 0.07, atY: 0.13, size: 1.2, alpha: 0.55),
            Star(atX: 0.16, atY: 0.71, size: 1.0, alpha: 0.35),
            Star(atX: 0.23, atY: 0.36, size: 0.8, alpha: 0.30),
            Star(atX: 0.31, atY: 0.88, size: 1.2, alpha: 0.50),
            Star(atX: 0.38, atY: 0.19, size: 0.9, alpha: 0.28),
            Star(atX: 0.46, atY: 0.57, size: 1.0, alpha: 0.34),
            Star(atX: 0.53, atY: 0.09, size: 0.8, alpha: 0.42),
            Star(atX: 0.61, atY: 0.79, size: 1.1, alpha: 0.30),
            Star(atX: 0.68, atY: 0.29, size: 0.8, alpha: 0.36),
            Star(atX: 0.74, atY: 0.93, size: 1.0, alpha: 0.44),
            Star(atX: 0.81, atY: 0.51, size: 1.3, alpha: 0.50),
            Star(atX: 0.88, atY: 0.16, size: 0.9, alpha: 0.32),
            Star(atX: 0.93, atY: 0.68, size: 0.8, alpha: 0.46),
            Star(atX: 0.96, atY: 0.41, size: 1.0, alpha: 0.26),
            Star(atX: 0.12, atY: 0.93, size: 0.8, alpha: 0.24),
            Star(atX: 0.57, atY: 0.44, size: 0.7, alpha: 0.22)
        ]
        for star in stars {
            palette.glass.withAlphaComponent(star.alpha * 0.45).setFill()
            NSBezierPath(ovalIn: NSRect(x: view.bounds.width * star.atX,
                                        y: view.bounds.height * star.atY,
                                        width: star.size, height: star.size)).fill()
        }
    }

    /// Les rails de coque et leurs graduations : l'échelle du vaisseau.
    private func drawHullRails(in view: PanelView) {
        let palette = view.theme.palette
        let railColor = palette.bezel.withAlphaComponent(0.55)
        for railX in [6.5, view.bounds.width - 6.5] {
            let rail = NSBezierPath()
            rail.move(to: NSPoint(x: railX, y: 22))
            rail.line(to: NSPoint(x: railX, y: view.bounds.height - 22))
            stroke(rail, railColor)
        }
        let ticks = NSBezierPath()
        var tickY: CGFloat = 34
        while tickY < view.bounds.height - 30 {
            ticks.move(to: NSPoint(x: 4, y: tickY))
            ticks.line(to: NSPoint(x: 9, y: tickY))
            ticks.move(to: NSPoint(x: view.bounds.width - 9, y: tickY))
            ticks.line(to: NSPoint(x: view.bounds.width - 4, y: tickY))
            tickY += 26
        }
        stroke(ticks, railColor.withAlphaComponent(0.7))
    }

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            let path = chamferedPath(rect, cut: 4)

            if active {
                palette.accent.setFill()
                path.fill()
                palette.accentSoft.withAlphaComponent(0.9).setFill()
                NSBezierPath(rect: NSRect(x: rect.minX + 4, y: rect.maxY - 2,
                                          width: rect.width - 8, height: 2)).fill()
            } else {
                palette.panelDeep.withAlphaComponent(0.8).setFill()
                path.fill()
                stroke(path, palette.bezel.withAlphaComponent(0.8))
            }

            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 10, y: rect.minY + 4),
                withAttributes: theme.type.attributes(
                    9, color: active ? palette.background : palette.dim,
                    bold: true, kern: 1.1))
        }

        drawLock(in: view, rect: pinRect)
    }

    /// Le verrou de la console : un cartouche, pas une punaise.
    private func drawLock(in view: PanelView, rect: NSRect) {
        let palette = view.theme.palette
        let path = chamferedPath(rect, cut: 4)

        if view.isPinned {
            palette.accent.withAlphaComponent(0.16).setFill()
            path.fill()
            stroke(path, palette.accent)
        } else {
            palette.panelDeep.withAlphaComponent(0.7).setFill()
            path.fill()
            stroke(path, palette.bezel.withAlphaComponent(0.8))
        }

        let tint = view.isPinned ? palette.accent : palette.dim
        let text = "LOCK"
        let attrs = view.theme.type.attributes(7, color: tint, bold: true, kern: 1.4)
        let width = text.size(withAttributes: attrs).width
        text.draw(at: NSPoint(x: rect.midX - width / 2, y: rect.minY + 5),
                  withAttributes: attrs)

        // Le témoin du verrou.
        tint.withAlphaComponent(view.isPinned ? 0.95 : 0.4).setFill()
        NSBezierPath(ovalIn: NSRect(x: rect.maxX - 7, y: rect.midY - 1.5,
                                    width: 3, height: 3)).fill()
    }

    // MARK: - Écran

    func drawScreen(in view: PanelView, spec: ScreenSpec) {
        let rect = spec.rect
        let label = spec.label
        let value = spec.value
        let sub = spec.sub
        let hot = spec.hot
        let small = spec.small
        let fraction = spec.fraction
        let tint = spec.tint
        let theme = view.theme
        let palette = theme.palette
        let meter = tint ?? palette.load(fraction)
        let valueColor = hot ? palette.danger : (tint ?? palette.accent)
        let path = chamferedPath(rect, cut: 6)

        palette.screen.setFill()
        path.fill()
        stroke(path, palette.bezel.withAlphaComponent(0.9))

        // Rail d'état sur le bord gauche : la couleur dit la charge avant
        // que l'œil n'ait lu le chiffre.
        palette.bezel.withAlphaComponent(0.45).setFill()
        NSBezierPath(rect: NSRect(x: rect.minX + 1, y: rect.minY + 5,
                                  width: 2, height: rect.height - 10)).fill()
        meter.withAlphaComponent(0.95).setFill()
        NSBezierPath(rect: NSRect(x: rect.minX + 1, y: rect.minY + 5,
                                  width: 2,
                                  height: max(2, (rect.height - 10)
                                              * CGFloat(max(0, min(1, fraction)))))).fill()

        // Encoche d'angle, côté opposé au biseau.
        palette.bezel.withAlphaComponent(0.6).setFill()
        NSBezierPath(rect: NSRect(x: rect.maxX - 10, y: rect.minY + 1,
                                  width: 8, height: 1)).fill()

        let labelAttrs = theme.type.attributes(8, color: palette.dim,
                                               bold: true, kern: 1.3)
        truncated(label, toWidth: rect.width - 18, attributes: labelAttrs)
            .draw(at: NSPoint(x: rect.minX + 9, y: rect.maxY - 15),
                  withAttributes: labelAttrs)

        let valueAttrs = theme.type.attributes(small ? 11 : 13,
                                               color: valueColor, bold: true,
                                               kern: 0.5)
        truncated(value, toWidth: rect.width - 18, attributes: valueAttrs)
            .draw(at: NSPoint(x: rect.minX + 9, y: rect.maxY - 34),
                  withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(8, color: palette.dim)
        truncated(sub, toWidth: rect.width - 18, attributes: subAttrs)
            .draw(at: NSPoint(x: rect.minX + 9, y: rect.maxY - 48),
                  withAttributes: subAttrs)

        // Jauge segmentée : douze cellules, comme une réserve de bord.
        drawSegmentedGauge(in: rect, fraction: fraction, meter: meter,
                           palette: palette)
    }

    /// La jauge segmentée d'un écran : douze cellules qui s'allument par
    /// crans, comme une réserve de bord.
    private func drawSegmentedGauge(in rect: NSRect, fraction: Double,
                                    meter: NSColor, palette: ThemePalette) {
        let count = 12
        let gap: CGFloat = 2
        let barWidth = rect.width - 18
        let segment = (barWidth - gap * CGFloat(count - 1)) / CGFloat(count)
        let filled = Int((max(0, min(1, fraction)) * Double(count)).rounded())
        for index in 0..<count {
            let cellX = rect.minX + 9 + CGFloat(index) * (segment + gap)
            let cell = NSRect(x: cellX, y: rect.minY + 6, width: segment, height: 3)
            if index < filled {
                meter.withAlphaComponent(0.95).setFill()
            } else {
                palette.bezel.withAlphaComponent(0.55).setFill()
            }
            NSBezierPath(rect: cell).fill()
        }
    }

    // MARK: - Ligne de processus

    func drawProcessAction(in view: PanelView, spec: ProcessActionSpec) {
        let rowRect = spec.rowRect
        let buttonRect = spec.buttonRect
        let title = spec.title
        let enabled = spec.enabled
        let hovered = spec.hovered
        let pending = spec.pending
        let theme = view.theme
        let palette = theme.palette

        if let pending {
            let elapsed = Date().timeIntervalSince(pending.since)
            if Int(elapsed * 4) % 2 == 0 {
                let attrs = theme.type.attributes(8, color: palette.warning,
                                                  bold: true, kern: 0.8)
                let width = pending.text.size(withAttributes: attrs).width
                pending.text.draw(at: NSPoint(x: buttonRect.maxX - width,
                                              y: buttonRect.minY + 3),
                                  withAttributes: attrs)
            }
            view.needsDisplay = true
            return
        }

        if hovered, enabled {
            palette.hover.setFill()
            NSBezierPath(rect: rowRect).fill()
        }

        let path = chamferedPath(buttonRect, cut: 3)
        if hovered, enabled {
            palette.danger.withAlphaComponent(0.18).setFill()
        } else {
            palette.panelDeep.withAlphaComponent(0.8).setFill()
        }
        path.fill()
        stroke(path, enabled
                ? palette.danger.withAlphaComponent(hovered ? 0.95 : 0.75)
                : palette.bezel.withAlphaComponent(0.6))

        let attrs = theme.type.attributes(8,
                                          color: enabled ? palette.danger : palette.dim,
                                          bold: true, kern: 1.1)
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 3),
                   withAttributes: attrs)
    }
}
