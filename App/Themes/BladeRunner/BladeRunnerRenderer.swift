//
//  BladeRunnerRenderer.swift
//  HAL
//
//  Le dessin Blade Runner : nuit bleue, pluie fine, néon cyan et rose,
//  écrans holographiques biseautés, œil de Tyrell dans l'en-tête. Aucun
//  coin franchement rond : la ville est faite de plaques et de reflets.
//

import AppKit

@MainActor

final class BladeRunnerRenderer: ThemeRenderer {

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            let path = chamfered(rect, cut: 5)

            if active {
                palette.accentSoft.withAlphaComponent(0.15).setFill()
                path.fill()
                palette.accentSoft.withAlphaComponent(0.85).setStroke()
            } else {
                palette.panelDeep.withAlphaComponent(0.85).setFill()
                path.fill()
                palette.dim.withAlphaComponent(0.38).setStroke()
            }
            path.lineWidth = 1
            path.stroke()

            if active {
                palette.accentSoft.setFill()
                NSBezierPath(rect: NSRect(x: rect.minX + 4, y: rect.minY + 3,
                                          width: 2, height: rect.height - 6)).fill()
            }

            let attrs = theme.type.attributes(
                8.5, color: active ? palette.accentSoft : palette.dim,
                bold: true, kern: 1.2, glow: active)
            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 10, y: rect.minY + 4),
                withAttributes: attrs)
        }

        drawLock(in: view, rect: pinRect)
    }

    /// Le verrou du spinner : un cadenas de console, à droite des onglets.
    private func drawLock(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let path = chamfered(rect, cut: 4)

        if view.isPinned {
            palette.accentSoft.withAlphaComponent(0.16).setFill()
            path.fill()
            palette.accentSoft.withAlphaComponent(0.8).setStroke()
        } else {
            palette.panelDeep.withAlphaComponent(0.85).setFill()
            path.fill()
            palette.dim.withAlphaComponent(0.38).setStroke()
        }
        path.lineWidth = 1
        path.stroke()

        let tint = view.isPinned ? palette.accentSoft : palette.dim
        tint.setStroke()
        tint.setFill()

        let lockX = rect.minX + 10
        let shackle = NSBezierPath()
        shackle.move(to: NSPoint(x: lockX - 3, y: rect.minY + 6))
        shackle.curve(to: NSPoint(x: lockX + 3, y: rect.minY + 6),
                      controlPoint1: NSPoint(x: lockX - 4, y: rect.minY + 12),
                      controlPoint2: NSPoint(x: lockX + 4, y: rect.minY + 12))
        shackle.lineWidth = 1.3
        shackle.stroke()

        NSBezierPath(roundedRect: NSRect(x: lockX - 4.5, y: rect.minY + 5,
                                         width: 9, height: 7),
                     xRadius: 1.5, yRadius: 1.5).fill()

        "LOCK".draw(at: NSPoint(x: rect.minX + 19, y: rect.minY + 5),
                    withAttributes: theme.type.attributes(
                        7, color: view.isPinned ? palette.accentSoft : palette.dim,
                        bold: true, kern: 1.2))
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
        let cap = tint ?? palette.load(fraction)
        let path = chamfered(rect, cut: 8)

        palette.screen.setFill()
        path.fill()

        // Voile holographique en haut de l'écran.
        palette.accent.withAlphaComponent(0.035).setFill()
        NSBezierPath(rect: NSRect(x: rect.minX + 1, y: rect.minY + 1,
                                  width: rect.width - 2, height: 16)).fill()

        cap.withAlphaComponent(hot ? 0.85 : 0.38).setStroke()
        path.lineWidth = 0.9
        path.stroke()

        // Capuchon rose, comme une diode de console.
        palette.accentSoft.withAlphaComponent(hot ? 0.95 : 0.55).setFill()
        NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY + 7,
                                  width: 2, height: rect.height - 14)).fill()

        // Crochets d'angle, en haut à droite.
        palette.accentSoft.withAlphaComponent(0.55).setStroke()
        let corner = NSBezierPath()
        corner.move(to: NSPoint(x: rect.maxX - 16, y: rect.minY + 1))
        corner.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY + 1))
        corner.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY + 10))
        corner.lineWidth = 0.8
        corner.stroke()

        let labelAttrs = theme.type.attributes(
            7.5, color: cap, bold: true, kern: 1.35)
        truncated(label, toWidth: rect.width - 26, attributes: labelAttrs)
            .draw(at: NSPoint(x: rect.minX + 10, y: rect.minY + 4),
                  withAttributes: labelAttrs)

        let valueColor = hot ? palette.danger : palette.text
        let valueAttrs = theme.type.attributes(
            small ? 15 : 19, color: valueColor, bold: true,
            kern: 0.3, glow: true)
        truncated(value, toWidth: rect.width - 26, attributes: valueAttrs)
            .draw(at: NSPoint(x: rect.minX + 10, y: rect.minY + 16),
                  withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(7.5, color: palette.dim, kern: 0.3)
        truncated(sub, toWidth: rect.width - 26, attributes: subAttrs)
            .draw(at: NSPoint(x: rect.minX + 10, y: rect.minY + 39),
                  withAttributes: subAttrs)

        drawGauge(in: NSRect(x: rect.minX + 10, y: rect.maxY - 7,
                             width: rect.width - 20, height: 3),
                  fraction: fraction, tint: cap, palette: palette)
    }

    /// Jauge fine, graduée : la charge se lit comme sur un cadran de
    /// spinner, sans aplats massifs.
    private func drawGauge(in rect: NSRect, fraction: Double,
                           tint: NSColor, palette: ThemePalette) {
        palette.dim.withAlphaComponent(0.18).setFill()
        NSBezierPath(rect: rect).fill()

        let clamped = max(0, min(1, fraction))
        if clamped > 0 {
            tint.withAlphaComponent(0.85).setFill()
            NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY,
                                      width: max(1.5, rect.width * CGFloat(clamped)),
                                      height: rect.height)).fill()
        }

        palette.background.withAlphaComponent(0.65).setFill()
        for step in 1..<10 {
            let tickX = rect.minX + rect.width * CGFloat(step) / 10
            NSBezierPath(rect: NSRect(x: tickX, y: rect.minY,
                                      width: 0.7, height: rect.height)).fill()
        }
    }

    // MARK: - Alertes

    func drawAlert(in view: PanelView, spec: AlertSpec) {
        let rect = spec.rect
        let kind = spec.kind
        let label = spec.label
        let message = spec.message
        let visible = spec.visible
        let theme = view.theme
        let palette = theme.palette
        let accent: NSColor = kind == .cpu ? palette.danger : palette.warning
        let path = chamfered(rect, cut: 6)

        if visible {
            accent.withAlphaComponent(0.88).setFill()
        } else {
            palette.panelDeep.withAlphaComponent(0.96).setFill()
        }
        path.fill()

        accent.withAlphaComponent(visible ? 1 : 0.45).setStroke()
        path.lineWidth = 1
        path.stroke()

        let textColor = visible ? palette.background : accent
        let labelAttrs = theme.type.attributes(
            9, color: textColor, bold: true, kern: 1.8, glow: visible)
        truncated(label, toWidth: 76, attributes: labelAttrs)
            .draw(at: NSPoint(x: rect.minX + 10, y: rect.minY + 7),
                  withAttributes: labelAttrs)

        let messageAttrs = theme.type.attributes(
            7.5, color: textColor, bold: true, kern: 1.0)
        let upper = message.uppercased(with: Locale(identifier: Localization.current))
        truncated(upper, toWidth: rect.width - 130, attributes: messageAttrs)
            .draw(at: NSPoint(x: rect.minX + 88, y: rect.minY + 8),
                  withAttributes: messageAttrs)

        // Chevrons de danger, à droite.
        accent.withAlphaComponent(visible ? 0.55 : 0.25).setStroke()
        for index in 0..<3 {
            let chevronX = rect.maxX - 34 + CGFloat(index) * 8
            let chevron = NSBezierPath()
            chevron.move(to: NSPoint(x: chevronX, y: rect.minY + 7))
            chevron.line(to: NSPoint(x: chevronX + 4, y: rect.midY))
            chevron.line(to: NSPoint(x: chevronX, y: rect.maxY - 7))
            chevron.lineWidth = 1.1
            chevron.stroke()
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
            drawPendingRequest(pending, in: view, rowRect: rowRect)
            return
        }

        if hovered, enabled {
            palette.hover.setFill()
            NSBezierPath(roundedRect: rowRect, xRadius: 3, yRadius: 3).fill()
        }

        let path = chamfered(buttonRect, cut: 4)
        if enabled {
            palette.danger.withAlphaComponent(hovered ? 0.22 : 0.08).setFill()
            path.fill()
        }
        palette.danger.withAlphaComponent(enabled ? 0.85 : 0.3).setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs = theme.type.attributes(
            7.5, color: enabled ? palette.danger : palette.dim,
            bold: true, kern: 1.4)
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 4),
                   withAttributes: attrs)
    }

    /// La demande d'autorisation en cours : un cadre biseauté qui clignote
    /// sur la ligne, le temps que le test réponde. La ligne continue de
    /// battre pendant le test.
    private func drawPendingRequest(_ pending: (text: String, since: Date),
                                    in view: PanelView, rowRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let overlay = NSRect(x: view.contentX + 200, y: rowRect.minY + 1,
                             width: view.bounds.width - view.padding
                                - view.contentX - 200,
                             height: 19)
        let path = chamfered(overlay, cut: 4)
        palette.panelDeep.withAlphaComponent(0.97).setFill()
        path.fill()
        palette.warning.withAlphaComponent(0.6).setStroke()
        path.lineWidth = 1
        path.stroke()

        let elapsed = Date().timeIntervalSince(pending.since)
        if Int(elapsed * 6) % 2 == 0 {
            let attrs = theme.type.attributes(
                7.5, color: palette.warning, bold: true, kern: 1.2)
            let text = pending.text
            let width = text.size(withAttributes: attrs).width
            text.draw(at: NSPoint(x: overlay.maxX - 8 - width,
                                  y: rowRect.minY + 6),
                      withAttributes: attrs)

            palette.warning.setFill()
            NSBezierPath(rect: NSRect(x: overlay.minX + 7,
                                      y: rowRect.minY + 8,
                                      width: 5, height: 5)).fill()
        }
        view.needsDisplay = true
    }

}
