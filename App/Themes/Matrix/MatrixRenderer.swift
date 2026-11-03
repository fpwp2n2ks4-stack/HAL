//
//  MatrixRenderer.swift
//  HAL
//
//  Rendu Matrix : écran noir, texte vert phosphore, lueur,
//  scanlines minimalistes.
//
import AppKit

@MainActor

final class MatrixRenderer: ThemeRenderer {

    // MARK: - Fond
    func drawBackground(in view: PanelView) {
        let palette = view.theme.palette
        let radius = view.theme.geometry.cornerRadius
        palette.background.setFill()
        NSBezierPath(roundedRect: view.bounds, xRadius: radius, yRadius: radius).fill()

        palette.bezel.withAlphaComponent(0.6).setStroke()
        let border = NSBezierPath(roundedRect: view.bounds.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: radius, yRadius: radius)
        border.lineWidth = 1
        border.stroke()
    }

    // MARK: - En-tête
    func drawHeader(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let padding = theme.geometry.padding

        let title = "> MATRIX"
        var titleAttrs = theme.type.attributes(13, color: palette.accent, bold: true)
        if let glow = theme.type.glow(palette.accent, radius: 4) {
            titleAttrs[.shadow] = glow
        }
        title.draw(at: NSPoint(x: padding, y: 12), withAttributes: titleAttrs)

        let clockFmt = DateFormatter()
        clockFmt.dateFormat = "EEEE d MMMM yyyy · HH:mm:ss"
        clockFmt.locale = Locale(identifier: Localization.current)
        let clock = clockFmt.string(from: view.snapshot.date)
        let clockAttrs = theme.type.attributes(10, color: palette.dim)
        let clockSize = clock.size(withAttributes: clockAttrs)
        clock.draw(at: NSPoint(x: view.bounds.width - padding - clockSize.width, y: 32),
                   withAttributes: clockAttrs)
    }

    // MARK: - Onglets
    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            if active {
                palette.accent.withAlphaComponent(0.12).setFill()
                NSBezierPath(rect: rect).fill()
                palette.accent.withAlphaComponent(0.8).setStroke()
                let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
                border.lineWidth = 1
                border.stroke()
            } else {
                palette.panelDeep.withAlphaComponent(0.6).setFill()
                NSBezierPath(rect: rect).fill()
                palette.bezel.withAlphaComponent(0.4).setStroke()
                let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
                border.lineWidth = 1
                border.stroke()
            }

            var attrs = theme.type.attributes(
                9, color: active ? palette.accent : palette.dim, bold: active)
            if active, let glow = theme.type.glow(palette.accent, radius: 3) {
                attrs[.shadow] = glow
            }
            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 6, y: rect.minY + 3), withAttributes: attrs)
        }

        drawPin(in: view, rect: pinRect)
    }

    private func drawPin(in view: PanelView, rect: NSRect) {
        let palette = view.theme.palette
        let tint = view.isPinned ? palette.accent : palette.dim

        palette.panelDeep.withAlphaComponent(0.6).setFill()
        NSBezierPath(rect: rect).fill()
        tint.withAlphaComponent(view.isPinned ? 0.9 : 0.4).setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        tint.setFill()
        NSBezierPath(rect: NSRect(x: rect.midX - 0.5, y: rect.minY + 4,
                                  width: 1, height: rect.height - 8)).fill()
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 2, y: rect.minY + 3,
                                    width: 4, height: 4)).fill()
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

        palette.screen.setFill()
        NSBezierPath(rect: rect).fill()

        palette.bezel.withAlphaComponent(0.6).setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        let labelAttrs = theme.type.attributes(9, color: palette.dim)
        label.draw(at: NSPoint(x: rect.minX + 6, y: rect.maxY - 14), withAttributes: labelAttrs)

        let valueColor = hot ? palette.danger : palette.accent
        var valueAttrs = theme.type.attributes(small ? 10 : 12, color: valueColor, bold: true)
        if let glow = theme.type.glow(valueColor, radius: 4) {
            valueAttrs[.shadow] = glow
        }
        value.draw(at: NSPoint(x: rect.minX + 6, y: rect.maxY - 33), withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(9, color: palette.dim)
        sub.draw(at: NSPoint(x: rect.minX + 6, y: rect.maxY - 46), withAttributes: subAttrs)

        let bar = NSRect(x: rect.minX + 6, y: rect.minY + 6,
                         width: rect.width - 12, height: 2)
        palette.bezel.withAlphaComponent(0.4).setFill()
        NSBezierPath(rect: bar).fill()
        let clamped = max(0, min(1, fraction))
        if clamped > 0 {
            let filled = NSRect(x: bar.minX, y: bar.minY,
                                width: max(2, bar.width * CGFloat(clamped)),
                                height: bar.height)
            accent.setFill()
            NSBezierPath(rect: filled).fill()
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
        let tint = kind == .cpu ? palette.danger : palette.warning

        palette.screen.withAlphaComponent(0.95).setFill()
        NSBezierPath(rect: rect).fill()

        tint.withAlphaComponent(visible ? 0.9 : 0.4).setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        guard visible else { return }
        let text = label.isEmpty ? message : "\(label) \(message)"
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
        NSColor.black.withAlphaComponent(0.25).setFill()
        var lineY: CGFloat = 0
        while lineY < view.bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: lineY,
                                      width: view.bounds.width, height: 1)).fill()
            lineY += 2
        }
    }

    // MARK: - Bande son
    func drawAudioBand(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        palette.screen.setFill()
        NSBezierPath(rect: rect).fill()
        palette.bezel.withAlphaComponent(0.6).setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        let playing = view.snapshot.nowPlaying
        let hasTrack = !playing.track.isEmpty
        "> AUDIO".draw(
            at: NSPoint(x: rect.minX + 6, y: rect.minY + 4),
            withAttributes: theme.type.attributes(8, color: palette.dim))

        if !hasTrack {
            "—".draw(
                at: NSPoint(x: rect.minX + 6, y: rect.midY - 4),
                withAttributes: theme.type.attributes(9, color: palette.dim))
            return
        }

        let artwork = view.artworkImage()
        let artSize = rect.height - 12
        var textX = rect.minX + 6
        var textWidth = rect.width - 12
        if let artwork {
            let frame = NSRect(x: rect.minX + 6, y: rect.midY - artSize / 2,
                               width: artSize, height: artSize)
            view.drawArtwork(artwork, in: frame,
                             border: palette.bezel,
                             shadow: false)
            textX = frame.maxX + 8
            textWidth = rect.maxX - 6 - textX
        }

        let metaAttrs = theme.type.attributes(8, color: palette.dim)
        var titleAttrs = theme.type.attributes(9, color: palette.accent, bold: true)
        if let glow = theme.type.glow(palette.accent, radius: 3) {
            titleAttrs[.shadow] = glow
        }
        let first = view.musicAlbumLine()
        if !first.isEmpty {
            view.drawMusicLine(first, x: textX, y: rect.midY - 9,
                               width: textWidth, attributes: metaAttrs)
        }
        let second = view.musicTitleLine()
        if !second.isEmpty {
            view.drawMusicLine(second, x: textX, y: rect.midY + 2,
                               width: textWidth, attributes: titleAttrs)
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
                var attrs = theme.type.attributes(8, color: palette.danger, bold: true)
                if let glow = theme.type.glow(palette.danger, radius: 3) {
                    attrs[.shadow] = glow
                }
                pending.text.draw(at: NSPoint(x: buttonRect.minX, y: buttonRect.minY + 3),
                                  withAttributes: attrs)
            }
            view.needsDisplay = true
            return
        }

        if hovered, enabled {
            palette.hover.setFill()
            NSBezierPath(rect: rowRect).fill()
        }

        palette.panelDeep.withAlphaComponent(0.7).setFill()
        NSBezierPath(rect: buttonRect).fill()
        let tint = enabled ? palette.danger : palette.dim
        tint.withAlphaComponent(enabled ? 0.9 : 0.4).setStroke()
        let border = NSBezierPath(rect: buttonRect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        var attrs = theme.type.attributes(8, color: enabled ? palette.danger : palette.dim, bold: true)
        if enabled, let glow = theme.type.glow(palette.danger, radius: 2) {
            attrs[.shadow] = glow
        }
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 3),
                   withAttributes: attrs)
    }
}
