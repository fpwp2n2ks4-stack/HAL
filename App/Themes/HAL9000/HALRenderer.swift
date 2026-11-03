//
//  HALRenderer.swift
//  HAL
//
//  Le dessin de HAL 9000 : tube cathodique vert, œil rouge, grille de
//  haut-parleur perforée, bouton « pod bay doors ».
//
//  Ce fichier est le seul endroit où les couleurs, les rayons et les
//  ombres de HAL sont écrits en dur. Le noyau, lui, ne voit que le
//  protocole `ThemeRenderer`.
//

import AppKit

@MainActor
final class HALRenderer: ThemeRenderer {

    // MARK: - Fond

    func drawBackground(in view: PanelView) {
        let palette = view.theme.palette
        let radius = view.theme.geometry.cornerRadius
        palette.background.setFill()
        NSBezierPath(roundedRect: view.bounds, xRadius: radius, yRadius: radius).fill()
    }

    // MARK: - En-tête

    func drawHeader(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let padding = theme.geometry.padding

        let title = "HAL - Hardware Autopsy Live"
        var titleAttrs = theme.type.attributes(13, color: palette.accent, bold: true)
        if let glow = theme.type.glow(palette.accent, radius: 5) {
            titleAttrs[.shadow] = glow
        }
        title.draw(at: NSPoint(x: padding, y: 12), withAttributes: titleAttrs)

        // L'œil veille, à droite de l'en-tête.
        let center = NSPoint(x: view.bounds.width - padding - 8, y: 20)
        let hot = view.snapshot.cpu.total >= 80
        let iris = hot
            ? palette.danger
            : NSColor(srgbRed: 0.65, green: 0.05, blue: 0.05, alpha: 1)

        iris.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 7, y: center.y - 7,
                                    width: 14, height: 14)).fill()
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 2.5, y: center.y - 3.5,
                                    width: 5, height: 7)).fill()
        NSColor.white.withAlphaComponent(0.85).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 3.5, y: center.y + 1.5,
                                    width: 2.5, height: 2)).fill()

        let modelAttrs = theme.type.attributes(10.5, color: palette.dim)
        let time = DateFormatter()
        time.dateFormat = "HH:mm:ss"
        let date = DateFormatter()
        date.dateStyle = .full
        date.timeStyle = .none
        date.locale = Locale(identifier: Localization.current)

        let machine = "\(HostInfo.modelString)  \(HostInfo.chipString)"
        machine.draw(at: NSPoint(x: padding, y: 32), withAttributes: modelAttrs)

        let clock = "\(date.string(from: view.snapshot.date))  \(time.string(from: view.snapshot.date))"
        let clockSize = clock.size(withAttributes: modelAttrs)
        clock.draw(at: NSPoint(x: view.bounds.width - padding - clockSize.width, y: 32),
                   withAttributes: modelAttrs)
    }

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            if active {
                palette.accent.withAlphaComponent(0.18).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).fill()
            }
            let attrs = theme.type.attributes(
                9, color: active ? palette.accent : palette.dim, bold: true)
            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 8, y: rect.minY + 3), withAttributes: attrs)
        }

        drawPin(in: view, rect: pinRect)
    }

    /// La punaise, à droite de la rangée d'onglets : une tête ronde, une
    /// tige, deux ailettes — reconnaissable à 16 px.
    private func drawPin(in view: PanelView, rect: NSRect) {
        let palette = view.theme.palette
        let tint = view.isPinned ? palette.accent : palette.dim

        if view.isPinned {
            palette.accent.withAlphaComponent(0.18).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).fill()
        }

        tint.setStroke()
        tint.setFill()
        let head = NSRect(x: rect.midX - 4, y: rect.minY + 4, width: 8, height: 5)
        NSBezierPath(roundedRect: head, xRadius: 2, yRadius: 2).fill()

        let stem = NSBezierPath()
        stem.move(to: NSPoint(x: rect.midX, y: rect.minY + 9))
        stem.line(to: NSPoint(x: rect.midX, y: rect.minY + 3))
        stem.lineWidth = 1.6
        stem.stroke()

        let wings = NSBezierPath()
        wings.move(to: NSPoint(x: rect.midX - 2.5, y: rect.minY + 4))
        wings.line(to: NSPoint(x: rect.midX + 2.5, y: rect.minY + 4))
        wings.lineWidth = 1
        wings.stroke()
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

        drawBezel(rect, view: view)

        let labelAttrs = theme.type.attributes(10, color: palette.dim, bold: true)
        label.draw(at: NSPoint(x: rect.minX + 10, y: rect.maxY - 13),
                   withAttributes: labelAttrs)

        let valueColor = hot ? palette.danger : palette.accent
        var valueAttrs = theme.type.attributes(
            small ? 10 : 12, color: valueColor, bold: true)
        if let glow = theme.type.glow(valueColor, radius: 5) {
            valueAttrs[.shadow] = glow
        }
        value.draw(at: NSPoint(x: rect.minX + 10, y: rect.maxY - 33),
                   withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(10.5, color: palette.dim)
        sub.draw(at: NSPoint(x: rect.minX + 10, y: rect.maxY - 46),
                 withAttributes: subAttrs)

        // Jauge de charge en haut de l'écran.
        let bar = NSRect(x: rect.minX + 10, y: rect.minY + 8,
                         width: rect.width - 20, height: 3)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSBezierPath(roundedRect: bar, xRadius: 1.5, yRadius: 1.5).fill()
        let clamped = max(0, min(1, fraction))
        if clamped > 0 {
            let filled = NSRect(x: bar.minX, y: bar.minY,
                                width: max(2, bar.width * clamped), height: bar.height)
            (tint ?? palette.load(clamped)).setFill()
            NSBezierPath(roundedRect: filled, xRadius: 1.5, yRadius: 1.5).fill()
        }
    }

    /// Bezelle d'un écran : corps sombre, liseré phosphore, scanlines
    /// internes et vignettage — un tube cathodique en miniature.
    private func drawBezel(_ rect: NSRect, view: PanelView) {
        let palette = view.theme.palette

        palette.screen.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()

        palette.bezel.setStroke()
        let border = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: 6, yRadius: 6)
        border.lineWidth = 1
        border.stroke()

        palette.accent.withAlphaComponent(0.25).setStroke()
        let inner = NSBezierPath(roundedRect: rect.insetBy(dx: 2.5, dy: 2.5),
                                 xRadius: 4, yRadius: 4)
        inner.lineWidth = 0.6
        inner.stroke()

        NSColor.black.withAlphaComponent(0.28).setFill()
        var lineY = rect.minY + 3
        while lineY < rect.maxY - 3 {
            NSBezierPath(rect: NSRect(x: rect.minX + 3, y: lineY,
                                      width: rect.width - 6, height: 1)).fill()
            lineY += 3
        }
    }

    // MARK: - Alertes

    func drawAlert(in view: PanelView, spec: AlertSpec) {
        let rect = spec.rect
        let kind = spec.kind
        let label = spec.label
        let message = spec.message
        let visible = spec.visible
        let palette = view.theme.palette
        let tint: NSColor
        let background: NSColor

        switch kind {
        case .cpu:
            tint = palette.danger
            background = NSColor(srgbRed: 0.35, green: 0.02, blue: 0.02, alpha: 1)
        case .memory:
            tint = palette.warning
            background = NSColor(srgbRed: 0.30, green: 0.20, blue: 0.02, alpha: 1)
        }

        background.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()

        tint.setStroke()
        let border = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: 4, yRadius: 4)
        border.lineWidth = 1
        border.stroke()

        guard visible else { return }

        let text = label.isEmpty ? message : "\(label) · \(message)"
        var attrs = view.theme.type.attributes(10, color: tint, bold: true)
        if let glow = view.theme.type.glow(tint, radius: 4) {
            attrs[.shadow] = glow
        }
        let size = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (view.bounds.width - size.width) / 2,
                              y: rect.minY + 5),
                  withAttributes: attrs)
    }

    // MARK: - Scanlines

    func drawScanlines(in view: PanelView) {
        NSColor.black.withAlphaComponent(0.16).setFill()
        var lineY: CGFloat = 0
        while lineY < view.bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: lineY,
                                      width: view.bounds.width, height: 1)).fill()
            lineY += 3
        }

        // Vignettage.
        if let vignette = NSGradient(colors: [
            .clear,
            NSColor.black.withAlphaComponent(0.35)
        ]) {
            vignette.draw(in: view.bounds.insetBy(dx: 2, dy: 2),
                          relativeCenterPosition: .zero)
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
        let palette = view.theme.palette

        if let pending {
            let elapsed = Date().timeIntervalSince(pending.since)
            if Int(elapsed * 6) % 2 == 0 {
                let attrs = view.theme.type.attributes(
                    9, color: palette.danger, bold: true)
                var glowAttrs = attrs
                if let glow = view.theme.type.glow(palette.danger, radius: 4) {
                    glowAttrs[.shadow] = glow
                }
                pending.text.uppercased(with: Locale(identifier: Localization.current))
                    .draw(at: NSPoint(x: buttonRect.minX, y: buttonRect.minY + 2),
                          withAttributes: glowAttrs)
            }
            // Le refus est de pure forme : la ligne continue de battre.
            view.needsDisplay = true
            return
        }

        if hovered, enabled {
            palette.danger.withAlphaComponent(0.15).setFill()
            NSBezierPath(roundedRect: rowRect, xRadius: 4, yRadius: 4).fill()
        }

        let attrs = view.theme.type.attributes(
            8, color: enabled ? palette.danger : palette.dim, bold: true)
        title.draw(at: NSPoint(x: buttonRect.minX + 7, y: buttonRect.minY + 4),
                   withAttributes: attrs)

        palette.danger.withAlphaComponent(enabled ? 0.8 : 0.3).setStroke()
        let border = NSBezierPath(roundedRect: buttonRect, xRadius: 3, yRadius: 3)
        border.lineWidth = 1
        border.stroke()
    }
}
