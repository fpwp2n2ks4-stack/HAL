//
//  LCARSConsoleRenderer.swift
//  HAL
//
//  Le dessin LCARS : blocs à capuchon coloré, jauges segmentées, formes
//  asymétriques, immatriculation de la Fédération. Aucun halo : une
//  console LCARS est plate, elle s'allume par aplats.
//

import AppKit

@MainActor

/// Quel(s) côté(s) d'un bloc restent arrondis. LCARS aime les formes
/// asymétriques : un bord rond, l'autre franc.
enum LCARSRound {
    case all
    case left
    case right
    case top
    case bottom
    case none
}

final class LCARSConsoleRenderer: ThemeRenderer {

    // MARK: - Fond

    func drawBackground(in view: PanelView) {
        let theme = view.theme
        theme.palette.background.setFill()
        NSBezierPath(roundedRect: view.bounds,
                     xRadius: theme.geometry.cornerRadius,
                     yRadius: theme.geometry.cornerRadius).fill()

        theme.palette.dim.withAlphaComponent(0.22).setStroke()
        let border = NSBezierPath(roundedRect: view.bounds.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: theme.geometry.cornerRadius,
                                  yRadius: theme.geometry.cornerRadius)
        border.lineWidth = 1
        border.stroke()
    }

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            if active {
                lcarsFill(rect, palette.accent, radius: 4)
            } else {
                lcarsFill(rect, palette.panelDeep, radius: 4)
                lcarsStroke(rect, palette.dim.withAlphaComponent(0.45), radius: 4)
            }
            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 11, y: rect.minY + 5),
                withAttributes: theme.type.attributes(
                    9, color: active ? palette.background : palette.accentSoft,
                    bold: true, kern: theme.type.kern))
        }

        drawLock(in: view, rect: pinRect)
    }

    /// Le verrou, à droite de la rangée d'onglets : verrouillé, la console
    /// refuse de se refermer au clic extérieur.
    private func drawLock(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        if view.isPinned {
            lcarsFill(rect, palette.accentSoft, radius: 4)
        } else {
            lcarsFill(rect, palette.panelDeep, radius: 4)
            lcarsStroke(rect, palette.dim.withAlphaComponent(0.45), radius: 4)
        }

        "LOCK".draw(
            at: NSPoint(x: rect.minX + 11, y: rect.minY + 5),
            withAttributes: theme.type.attributes(
                8, color: view.isPinned ? palette.background : palette.dim,
                bold: true, kern: 1.5))
    }

    // MARK: - Bloc de données

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

        lcarsFill(rect, palette.panelDeep, radius: 6)
        lcarsFill(NSRect(x: rect.minX, y: rect.minY, width: 6, height: rect.height),
                  cap, radius: 5, round: .left)
        cap.withAlphaComponent(0.55).setFill()
        NSBezierPath(rect: NSRect(x: rect.minX + 12, y: rect.minY + 2,
                                  width: rect.width - 16, height: 1)).fill()

        let labelAttrs = theme.type.attributes(
            8, color: cap, bold: true, kern: 1.2)
        let displayLabel = label.uppercased(with: Locale(identifier: Localization.current))
        truncated(displayLabel, toWidth: rect.width - 24, attributes: labelAttrs)
            .draw(at: NSPoint(x: rect.minX + 14, y: rect.minY + 7),
                  withAttributes: labelAttrs)

        let valueAttrs = theme.type.attributes(
            small ? 15 : 19, color: hot ? palette.danger : palette.text,
            bold: true, kern: 0.3)
        truncated(value, toWidth: rect.width - 24, attributes: valueAttrs)
            .draw(at: NSPoint(x: rect.minX + 14, y: rect.minY + (small ? 21 : 17)),
                  withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(
            8, color: palette.dim, kern: 0.4)
        truncated(sub, toWidth: rect.width - 24, attributes: subAttrs)
            .draw(at: NSPoint(x: rect.minX + 14, y: rect.minY + 39),
                  withAttributes: subAttrs)

        drawSegmentedBar(in: NSRect(x: rect.minX + 14, y: rect.maxY - 10,
                                    width: rect.width - 24, height: 4),
                         fraction: fraction, tint: cap, palette: palette)
    }

    /// Jauge faite de segments : la lecture d'une charge sur une console
    /// LCARS se fait au nombre d'éléments allumés.
    private func drawSegmentedBar(in rect: NSRect, fraction: Double,
                                  tint: NSColor, palette: ThemePalette) {
        let segments = 18
        let gap: CGFloat = 2
        let segmentWidth = max(1, (rect.width - gap * CGFloat(segments - 1))
            / CGFloat(segments))
        let clamped = max(0, min(1, fraction))
        let filled = Int((clamped * Double(segments)).rounded(.up))

        for index in 0..<segments {
            let segmentX = rect.minX + CGFloat(index) * (segmentWidth + gap)
            let segment = NSRect(x: segmentX, y: rect.minY, width: segmentWidth, height: rect.height)
            (index < filled ? tint : palette.panel).setFill()
            NSBezierPath(rect: segment).fill()
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
        let flashing = visible

        let fill: NSColor
        let textColor: NSColor
        switch kind {
        case .cpu:
            fill = flashing
                ? palette.danger
                : NSColor(srgbRed: 0.330, green: 0.020, blue: 0.020, alpha: 1)
            textColor = flashing ? palette.background : palette.accentSoft
        case .memory:
            fill = flashing ? palette.warning : palette.panelDeep
            textColor = flashing ? palette.background : palette.warning
        }

        lcarsFill(rect, fill, radius: 4)

        let labelAttrs = theme.type.attributes(
            9, color: textColor, bold: true, kern: 1.6)
        label.draw(at: NSPoint(x: rect.minX + 12, y: rect.minY + 7),
                   withAttributes: labelAttrs)

        let messageAttrs = theme.type.attributes(
            8, color: textColor, bold: true, kern: 1.0)
        let messageStart = rect.minX + 92
        let messageWidth = rect.maxX - 20 - messageStart
        let upper = message.uppercased(with: Locale(identifier: Localization.current))
        truncated(upper, toWidth: messageWidth, attributes: messageAttrs)
            .draw(at: NSPoint(x: messageStart, y: rect.minY + 8),
                  withAttributes: messageAttrs)

        if flashing {
            palette.background.setFill()
            NSBezierPath(rect: NSRect(x: rect.maxX - 16, y: rect.minY + 8,
                                      width: 7, height: 8)).fill()
        }
    }

    // MARK: - Scanlines

    /// Une console LCARS est plate : aucun balayage de tube.
    func drawScanlines(in view: PanelView) {}

    // MARK: - Ligne de programme

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
            // Bandeau sombre par-dessus la valeur CPU et le bouton : la
            // ligne ne montre plus qu'une chose, l'ordre en attente.
            let overlay = NSRect(x: view.contentX + 210, y: rowRect.minY + 1,
                                 width: view.bounds.width - view.padding
                                    - view.contentX - 210,
                                 height: 19)
            lcarsFill(overlay, palette.panelDeep, radius: 3)
            lcarsStroke(overlay, palette.warning.withAlphaComponent(0.55), radius: 3)

            let elapsed = Date().timeIntervalSince(pending.since)
            if Int(elapsed * 6) % 2 == 0 {
                let attrs = theme.type.attributes(
                    7.5, color: palette.warning, bold: true, kern: 1.1)
                let text = pending.text
                let width = text.size(withAttributes: attrs).width
                text.draw(at: NSPoint(x: overlay.maxX - 6 - width,
                                      y: rowRect.minY + 6),
                          withAttributes: attrs)
                palette.warning.setFill()
                NSBezierPath(rect: NSRect(x: overlay.minX + 6,
                                          y: rowRect.minY + 8,
                                          width: 5, height: 5)).fill()
            }
            view.needsDisplay = true
            return
        }

        if hovered, enabled {
            palette.hover.setFill()
            NSBezierPath(roundedRect: rowRect, xRadius: 4, yRadius: 4).fill()
        }

        lcarsStroke(buttonRect,
                    enabled ? palette.danger : palette.dim.withAlphaComponent(0.4),
                    radius: 3)
        let attrs = theme.type.attributes(
            7.5, color: enabled ? palette.danger : palette.dim,
            bold: true, kern: 1.3)
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 4),
                   withAttributes: attrs)
    }

    // MARK: - Formes

    /// Remplit un rectangle LCARS en n'arrondissant que les côtés demandés.
    func lcarsFill(_ rect: NSRect, _ color: NSColor,
                   radius: CGFloat = 8, round: LCARSRound = .all) {
        guard rect.width > 0, rect.height > 0 else { return }
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()

        switch round {
        case .all, .none:
            break
        case .left:
            NSRect(x: rect.midX, y: rect.minY,
                   width: rect.width / 2, height: rect.height).fill()
        case .right:
            NSRect(x: rect.minX, y: rect.minY,
                   width: rect.width / 2, height: rect.height).fill()
        case .top:
            NSRect(x: rect.minX, y: rect.midY,
                   width: rect.width, height: rect.height / 2).fill()
        case .bottom:
            NSRect(x: rect.minX, y: rect.minY,
                   width: rect.width, height: rect.height / 2).fill()
        }
    }

    private func lcarsStroke(_ rect: NSRect, _ color: NSColor,
                             radius: CGFloat = 8, width: CGFloat = 1) {
        guard rect.width > 0, rect.height > 0 else { return }
        color.setStroke()
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: width / 2, dy: width / 2),
                                xRadius: radius, yRadius: radius)
        path.lineWidth = width
        path.stroke()
    }

    /// Le delta de la Fédération, pointe en haut, encoche au centre de la
    /// base. Dessiné dans le repère retourné du panneau.
    private func deltaPath(in rect: NSRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.midX, y: rect.minY + 1))
        path.line(to: NSPoint(x: rect.maxX - 1, y: rect.maxY - 1))
        path.line(to: NSPoint(x: rect.midX + 3, y: rect.maxY - 5))
        path.line(to: NSPoint(x: rect.midX, y: rect.maxY - 2.5))
        path.line(to: NSPoint(x: rect.midX - 3, y: rect.maxY - 5))
        path.line(to: NSPoint(x: rect.minX + 1, y: rect.maxY - 1))
        path.close()
        return path
    }
}

// MARK: - En-tête

extension LCARSConsoleRenderer {

    // MARK: - En-tête

    func drawHeader(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let padding = theme.geometry.padding

        // Bloc d'immatriculation, en haut à droite.
        let blockW: CGFloat = 176
        let blockX = view.bounds.width - padding - blockW
        lcarsFill(NSRect(x: blockX, y: 0, width: blockW, height: 48),
                  palette.accentSoft, radius: 7, round: .right)

        let badge = NSRect(x: blockX + 9, y: 13, width: 22, height: 21)
        palette.background.setFill()
        deltaPath(in: badge).fill()

        "STARDATE".draw(
            at: NSPoint(x: blockX + 39, y: 6),
            withAttributes: theme.type.attributes(
                7, color: palette.background, bold: true, kern: 1.6))
        Stardate.string(for: view.snapshot.date).draw(
            at: NSPoint(x: blockX + 39, y: 15),
            withAttributes: theme.type.attributes(
                15, color: palette.background, bold: true, kern: 0.6))

        let time = DateFormatter()
        time.dateFormat = "HH:mm:ss"
        time.string(from: view.snapshot.date).draw(
            at: NSPoint(x: blockX + 39, y: 33),
            withAttributes: theme.type.attributes(
                8, color: palette.background, bold: true, kern: 1.2))

        // Nom du vaisseau.
        let title = "U.S.S. \(HostInfo.shipName)"
        let titleAttrs = theme.type.attributes(
            16, color: palette.accentSoft, bold: true, kern: 0.4)
        let titleWidth = blockX - padding - 6
        truncated(title, toWidth: titleWidth, attributes: titleAttrs)
            .draw(at: NSPoint(x: padding, y: 5), withAttributes: titleAttrs)

        let subtitle = "FEDERATION STARSHIP · \(HostInfo.registry) · \(HostInfo.modelString)"
        let subtitleAttrs = theme.type.attributes(
            8, color: palette.dim, bold: true, kern: 0.9)
        truncated(subtitle, toWidth: titleWidth, attributes: subtitleAttrs)
            .draw(at: NSPoint(x: padding, y: 28), withAttributes: subtitleAttrs)
    }
}
