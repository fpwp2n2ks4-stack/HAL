//
//  WarGamesRenderer.swift
//  HAL
//
//  Le dessin WarGames : un terminal phosphore vert de 1983, des cadres en
//  caractères, un curseur qui clignote, des jauges en blocs pleins. Rien de
//  rond, rien de brillant : l'écran d'un WOPR n'a jamais connu l'antialiasing
//  des interfaces modernes.
//

import AppKit

@MainActor

final class WarGamesRenderer: ThemeRenderer {

    // MARK: - Fond

    func drawBackground(in view: PanelView) {
        let palette = view.theme.palette
        let radius = view.theme.geometry.cornerRadius

        palette.background.setFill()
        NSBezierPath(roundedRect: view.bounds, xRadius: radius, yRadius: radius).fill()

        // Lueur de phosphore : plus dense en haut, éteinte en bas.
        if let bloom = NSGradient(colors: [
            palette.accent.withAlphaComponent(0.055),
            .clear
        ]) {
            bloom.draw(in: NSRect(x: 0, y: 0,
                                  width: view.bounds.width,
                                  height: view.bounds.height * 0.55),
                       angle: -90)
        }

        drawGrid(in: view)

        palette.accent.withAlphaComponent(0.30).setStroke()
        let border = NSBezierPath(roundedRect: view.bounds.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: radius, yRadius: radius)
        border.lineWidth = 1
        border.stroke()

        palette.accent.withAlphaComponent(0.10).setStroke()
        let inner = NSBezierPath(roundedRect: view.bounds.insetBy(dx: 3.5, dy: 3.5),
                                 xRadius: max(1, radius - 2),
                                 yRadius: max(1, radius - 2))
        inner.lineWidth = 0.6
        inner.stroke()
    }

    /// Trame de terminal : des lignes très pâles, comme la rémanence d'un
    /// tube qui n'a jamais vraiment éteint ses caractères.
    private func drawGrid(in view: PanelView) {
        let palette = view.theme.palette
        let path = NSBezierPath()
        var scanY: CGFloat = 12
        while scanY < view.bounds.height {
            path.move(to: NSPoint(x: 0, y: scanY))
            path.line(to: NSPoint(x: view.bounds.width, y: scanY))
            scanY += 12
        }
        palette.accent.withAlphaComponent(0.022).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)

            if active {
                // Vidéo inverse : l'onglet actif est un bloc de phosphore.
                palette.accent.withAlphaComponent(0.92).setFill()
                path.fill()
            } else {
                palette.panelDeep.withAlphaComponent(0.7).setFill()
                path.fill()
                palette.dim.withAlphaComponent(0.35).setStroke()
                path.lineWidth = 1
                path.stroke()
            }

            let attrs = theme.type.attributes(
                8, color: active ? palette.background : palette.dim,
                bold: true, kern: 1.1)
            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 7, y: rect.minY + 4),
                withAttributes: attrs)
        }

        drawHold(in: view, rect: pinRect)
    }

    /// Le verrou du terminal : « HOLD » quand le panneau est épinglé.
    private func drawHold(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)

        if view.isPinned {
            palette.accent.withAlphaComponent(0.88).setFill()
            path.fill()
        } else {
            palette.panelDeep.withAlphaComponent(0.7).setFill()
            path.fill()
            palette.dim.withAlphaComponent(0.35).setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        let text = view.isPinned ? "HELD" : "HOLD"
        let attrs = theme.type.attributes(
            7, color: view.isPinned ? palette.background : palette.dim,
            bold: true, kern: 1.2)
        let width = text.size(withAttributes: attrs).width
        text.draw(at: NSPoint(x: rect.midX - width / 2, y: rect.minY + 5),
                  withAttributes: attrs)
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
        let accent = hot ? palette.danger : cap

        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        palette.screen.setFill()
        path.fill()

        accent.withAlphaComponent(hot ? 0.95 : 0.55).setStroke()
        path.lineWidth = 1
        path.stroke()

        drawCornerTicks(in: rect, color: accent.withAlphaComponent(0.8))

        let labelText = "> " + label
        let labelAttrs = theme.type.attributes(
            7.5, color: accent, bold: true, kern: 1.1)
        truncated(labelText, toWidth: rect.width - 34, attributes: labelAttrs)
            .draw(at: NSPoint(x: rect.minX + 8, y: rect.minY + 5),
                  withAttributes: labelAttrs)

        // L'état du canal, à droite du libellé.
        let state = hot ? "!!" : "OK"
        let stateAttrs = theme.type.attributes(
            7.5, color: hot ? palette.danger : palette.dim, bold: true)
        let stateWidth = state.size(withAttributes: stateAttrs).width
        state.draw(at: NSPoint(x: rect.maxX - 8 - stateWidth, y: rect.minY + 5),
                   withAttributes: stateAttrs)

        let valueColor = hot ? palette.danger : palette.text
        let valueAttrs = theme.type.attributes(
            small ? 13 : 17, color: valueColor, bold: true,
            kern: 0.3, glow: true)
        truncated(value, toWidth: rect.width - 18, attributes: valueAttrs)
            .draw(at: NSPoint(x: rect.minX + 8, y: rect.minY + 16),
                  withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(7.5, color: palette.dim, kern: 0.2)
        truncated(sub, toWidth: rect.width - 18, attributes: subAttrs)
            .draw(at: NSPoint(x: rect.minX + 8, y: rect.minY + 39),
                  withAttributes: subAttrs)

        drawBlockGauge(in: NSRect(x: rect.minX + 8, y: rect.maxY - 9,
                                  width: rect.width - 16, height: 5),
                       fraction: fraction, tint: cap, palette: palette)
    }

    /// Deux équerres aux angles, comme les cadres dessinés à la main dans
    /// les listings d'autrefois.
    private func drawCornerTicks(in rect: NSRect, color: NSColor) {
        color.setStroke()
        let length: CGFloat = 7
        let path = NSBezierPath()
        // Coin supérieur gauche.
        path.move(to: NSPoint(x: rect.minX, y: rect.minY + length))
        path.line(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX + length, y: rect.minY))
        // Coin inférieur droit.
        path.move(to: NSPoint(x: rect.maxX - length, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - length))
        path.lineWidth = 1.4
        path.stroke()
    }

    /// Jauge en blocs pleins : la charge se lit comme une barre de
    /// caractères sur un terminal.
    private func drawBlockGauge(in rect: NSRect, fraction: Double,
                                tint: NSColor, palette: ThemePalette) {
        let segments = 24
        let gap: CGFloat = 1
        let width = max(1, (rect.width - gap * CGFloat(segments - 1))
            / CGFloat(segments))
        let clamped = max(0, min(1, fraction))
        let lit = Int((clamped * Double(segments)).rounded())

        for index in 0..<segments {
            let blockX = rect.minX + CGFloat(index) * (width + gap)
            let block = NSRect(x: blockX, y: rect.minY, width: width, height: rect.height)
            if index < lit {
                tint.withAlphaComponent(0.92).setFill()
            } else {
                palette.dim.withAlphaComponent(0.22).setFill()
            }
            NSBezierPath(rect: block).fill()
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
            palette.accent.withAlphaComponent(0.08).setFill()
            NSBezierPath(rect: rowRect).fill()
        }

        let path = NSBezierPath(rect: buttonRect)
        if enabled {
            palette.danger.withAlphaComponent(hovered ? 0.20 : 0.06).setFill()
            path.fill()
        }
        palette.danger.withAlphaComponent(enabled ? 0.85 : 0.3).setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs = theme.type.attributes(
            7.5, color: enabled ? palette.danger : palette.dim,
            bold: true, kern: 1.2)
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 4),
                   withAttributes: attrs)
    }

    /// La demande d'autorisation en cours : un cadre qui clignote sur la
    /// ligne, le temps que la simulation réponde. Elle continue de tourner
    /// pendant le rituel.
    private func drawPendingRequest(_ pending: (text: String, since: Date),
                                    in view: PanelView, rowRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let overlay = NSRect(x: view.contentX + 200, y: rowRect.minY + 1,
                             width: view.bounds.width - view.padding
                                - view.contentX - 200,
                             height: 19)
        palette.screen.setFill()
        NSBezierPath(rect: overlay).fill()
        palette.warning.withAlphaComponent(0.7).setStroke()
        let border = NSBezierPath(rect: overlay)
        border.lineWidth = 1
        border.stroke()

        let elapsed = Date().timeIntervalSince(pending.since)
        if Int(elapsed * 6) % 2 == 0 {
            let attrs = theme.type.attributes(
                7.5, color: palette.warning, bold: true, kern: 1.0)
            let text = pending.text
            let width = text.size(withAttributes: attrs).width
            text.draw(at: NSPoint(x: overlay.maxX - 8 - width,
                                  y: rowRect.minY + 6),
                      withAttributes: attrs)

            palette.warning.setFill()
            NSBezierPath(rect: NSRect(x: overlay.minX + 7,
                                      y: rowRect.minY + 7,
                                      width: 5, height: 5)).fill()
        }
        view.needsDisplay = true
    }
}

// MARK: - En-tête

extension WarGamesRenderer {

    // MARK: - En-tête

    func drawHeader(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let padding = theme.geometry.padding

        let title = "WOPR"
        var titleAttrs = theme.type.attributes(
            20, color: palette.accent, bold: true, kern: 2.4)
        if let glow = theme.type.glow(palette.accent, radius: 6) {
            titleAttrs[.shadow] = glow
        }
        title.draw(at: NSPoint(x: padding, y: 3), withAttributes: titleAttrs)

        let titleWidth = title.size(withAttributes: titleAttrs).width
        "WAR OPERATION PLAN RESPONSE".draw(
            at: NSPoint(x: padding + titleWidth + 10, y: 10),
            withAttributes: theme.type.attributes(
                7.5, color: palette.dim, bold: true, kern: 1.4))

        "JOSHUA · NORAD · CHEYENNE MOUNTAIN".draw(
            at: NSPoint(x: padding, y: 27),
            withAttributes: theme.type.attributes(
                8, color: palette.accentSoft, bold: true, kern: 0.8))

        let clock = Self.clock.string(from: view.snapshot.date)
        let status = "DEFCON 5 · SYSTEM READY · \(clock)"
        let statusAttrs = theme.type.attributes(
            7.5, color: palette.dim, bold: true, kern: 1.1)
        truncated(status, toWidth: view.bounds.width - 150, attributes: statusAttrs)
            .draw(at: NSPoint(x: padding, y: 43), withAttributes: statusAttrs)

        drawTerminalBadge(in: view)
    }

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Le petit terminal de l'en-tête : un écran CRT, une invite, un
    /// curseur. Il porte l'infobulle et la voix.
    private func drawTerminalBadge(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let frame = theme.geometry.headerTipRect(in: view.bounds.width)

        let body = NSRect(x: frame.minX + 8, y: frame.minY + 2,
                          width: frame.width - 16, height: 19)
        palette.panelDeep.setFill()
        NSBezierPath(roundedRect: body, xRadius: 3, yRadius: 3).fill()
        palette.accent.withAlphaComponent(0.75).setStroke()
        let shell = NSBezierPath(roundedRect: body, xRadius: 3, yRadius: 3)
        shell.lineWidth = 1
        shell.stroke()

        let screen = body.insetBy(dx: 2.5, dy: 2.5)
        palette.screen.setFill()
        NSBezierPath(rect: screen).fill()

        let promptAttrs = theme.type.attributes(
            7.5, color: palette.accent, bold: true)
        ">".draw(at: NSPoint(x: screen.minX + 2, y: screen.minY + 2),
                 withAttributes: promptAttrs)

        // Curseur plein, clignotant au rythme de l'horloge.
        let phase = Int(Date().timeIntervalSinceReferenceDate * 2) % 2
        if phase == 0 {
            palette.accent.setFill()
            NSBezierPath(rect: NSRect(x: screen.minX + 11, y: screen.minY + 3,
                                      width: 4, height: 7)).fill()
        }

        // Le pied du moniteur.
        palette.accent.withAlphaComponent(0.55).setFill()
        NSBezierPath(rect: NSRect(x: body.midX - 5, y: body.maxY + 1,
                                  width: 10, height: 2)).fill()
        NSBezierPath(rect: NSRect(x: body.midX - 10, y: body.maxY + 3,
                                  width: 20, height: 1.5)).fill()
    }
}
