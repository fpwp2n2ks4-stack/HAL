//
//  MoonRenderer.swift
//  HAL
//
//  Le dessin Moon : fond beige-grisâtre, panneau GERTY avec visage
//  souriant bleu, texte sobre. Tout est aussi neutre que possible.
//

import AppKit

@MainActor

final class MoonRenderer: ThemeRenderer {

    // MARK: - Fond

    func drawBackground(in view: PanelView) {
        let palette = view.theme.palette
        let radius = view.theme.geometry.cornerRadius

        palette.background.setFill()
        NSBezierPath(roundedRect: view.bounds, xRadius: radius, yRadius: radius).fill()

        palette.bezel.withAlphaComponent(0.5).setStroke()
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

        let textX = padding + 4
        let title = "GERTY 3000"
        title.draw(at: NSPoint(x: textX, y: 22),
                   withAttributes: theme.type.attributes(
                    15, color: palette.text, bold: true, kern: 0.2))

        let subtitle = "LUNAR INDUSTRIES"
        subtitle.draw(at: NSPoint(x: textX, y: 44),
                      withAttributes: theme.type.attributes(
                        9, color: palette.dim, kern: 0.6))

        let clock = Self.clock.string(from: view.snapshot.date)
        let meta = "\(clock)"
        let metaAttrs = theme.type.attributes(10, color: palette.text)
        let metaWidth = meta.size(withAttributes: metaAttrs).width
        meta.draw(at: NSPoint(x: (view.bounds.width - metaWidth) / 2, y: 44),
                  withAttributes: metaAttrs)

        drawSmiley(in: view)
    }

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Le visage GERTY : un grand rond jaune, deux yeux ronds, bouche
    /// souriante. C'est ça qu'on voit dans le film.
    private func drawSmiley(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        var frame = theme.geometry.headerTipRect(in: view.bounds.width)
        frame = NSRect(x: frame.maxX - frame.width,
                       y: frame.origin.y,
                       width: frame.width,
                       height: frame.height)

        palette.accent.setFill()
        NSBezierPath(ovalIn: frame).fill()

        // Yeux en haut.
        NSColor.black.withAlphaComponent(0.9).setFill()
        NSBezierPath(ovalIn: NSRect(x: frame.minX + 17, y: frame.minY + 20,
                                    width: 7, height: 7)).fill()
        NSBezierPath(ovalIn: NSRect(x: frame.minX + 34, y: frame.minY + 20,
                                    width: 7, height: 7)).fill()

        // Sourire en bas.
        NSColor.black.withAlphaComponent(0.9).setStroke()
        let smile = NSBezierPath()
        smile.move(to: NSPoint(x: frame.minX + 18, y: frame.minY + 38))
        smile.curve(to: NSPoint(x: frame.minX + 40, y: frame.minY + 38),
                    controlPoint1: NSPoint(x: frame.minX + 22, y: frame.minY + 45),
                    controlPoint2: NSPoint(x: frame.minX + 36, y: frame.minY + 45))
        smile.lineWidth = 2.0
        smile.stroke()
    }

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            let path = NSBezierPath(rect: rect)

            if active {
                palette.panel.setFill()
                path.fill()
                palette.accent.withAlphaComponent(0.9).setStroke()
                path.lineWidth = 1
                path.stroke()
            } else {
                palette.panelDeep.withAlphaComponent(0.8).setFill()
                path.fill()
                palette.bezel.withAlphaComponent(0.6).setStroke()
                path.lineWidth = 1
                path.stroke()
            }

            let attrs = theme.type.attributes(
                9, color: active ? palette.text : palette.dim,
                bold: false)
            (theme.copy.tabTitles[entry] ?? "").draw(
                at: NSPoint(x: rect.minX + 8, y: rect.minY + 3),
                withAttributes: attrs)
        }

        drawPin(in: view, rect: pinRect)
    }

    private func drawPin(in view: PanelView, rect: NSRect) {
        let palette = view.theme.palette
        let path = NSBezierPath(rect: rect)

        palette.panelDeep.withAlphaComponent(0.8).setFill()
        path.fill()
        palette.bezel.withAlphaComponent(0.6).setStroke()
        path.lineWidth = 1
        path.stroke()

        let tint = view.isPinned ? palette.accent : palette.dim
        tint.setStroke()
        NSBezierPath(rect: NSRect(x: rect.midX - 0.5, y: rect.minY + 4,
                                  width: 1, height: rect.height - 8)).stroke()
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 2, y: rect.minY + 3,
                                    width: 4, height: 4)).stroke()
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

        let path = NSBezierPath(rect: rect)
        palette.panel.withAlphaComponent(0.9).setFill()
        path.fill()

        palette.bezel.withAlphaComponent(0.7).setStroke()
        path.lineWidth = 1
        path.stroke()

        // Etiquette sobre.
        let labelAttrs = theme.type.attributes(
            9, color: palette.text, kern: 0.4)
        label.draw(at: NSPoint(x: rect.minX + 8, y: rect.maxY - 14),
                   withAttributes: labelAttrs)

        let valueColor = hot ? palette.danger : palette.text
        let valueAttrs = theme.type.attributes(
            small ? 11 : 13, color: valueColor)
        value.draw(at: NSPoint(x: rect.minX + 8, y: rect.maxY - 33),
                   withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(8, color: palette.text)
        sub.draw(at: NSPoint(x: rect.minX + 8, y: rect.maxY - 46),
                  withAttributes: subAttrs)

        // Barre sobre, horizontale.
        let bar = NSRect(x: rect.minX + 8, y: rect.minY + 8,
                         width: rect.width - 16, height: 2)
        palette.bezel.withAlphaComponent(0.4).setFill()
        NSBezierPath(rect: bar).fill()
        let clamped = max(0, min(1, fraction))
        if clamped > 0 {
            let filled = NSRect(x: bar.minX, y: bar.minY,
                                width: max(2, bar.width * CGFloat(clamped)),
                                height: bar.height)
            accent.withAlphaComponent(hot ? 0.9 : 0.7).setFill()
            NSBezierPath(rect: filled).fill()
        }
    }

    // MARK: - Alertes

    func drawAlert(in view: PanelView, spec: AlertSpec) {
        let rect = spec.rect
        let kind = spec.kind
        let visible = spec.visible
        let palette = view.theme.palette
        let tint: NSColor = kind == .cpu ? palette.danger : palette.warning

        palette.panel.withAlphaComponent(0.95).setFill()
        NSBezierPath(rect: rect).fill()

        tint.withAlphaComponent(visible ? 0.9 : 0.4).setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        let text = visible ? "ATTENTION, SAM" : "ATTENTION"
        let attrs = view.theme.type.attributes(
            9, color: visible ? tint : palette.dim)
        let size = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (view.bounds.width - size.width) / 2,
                              y: rect.minY + 6),
                  withAttributes: attrs)
    }

    // MARK: - Scanlines

    func drawScanlines(in view: PanelView) {
        // Très sobre, à peine perceptible.
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
            if Int(elapsed * 2) % 2 == 0 {
                let attrs = theme.type.attributes(
                    8, color: palette.dim)
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

        let path = NSBezierPath(rect: buttonRect)
        palette.panelDeep.withAlphaComponent(0.8).setFill()
        path.fill()
        let tint = enabled ? palette.accent : palette.dim
        tint.withAlphaComponent(enabled ? 0.7 : 0.4).setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs = theme.type.attributes(
            8, color: enabled ? palette.text : palette.dim)
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 3),
                   withAttributes: attrs)
    }
}

// MARK: - Bande son

extension MoonRenderer {

    func drawAudioBand(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let path = NSBezierPath(rect: rect)

        palette.panel.withAlphaComponent(0.9).setFill()
        path.fill()
        palette.bezel.withAlphaComponent(0.7).setStroke()
        path.lineWidth = 1
        path.stroke()

        let playing = view.snapshot.nowPlaying
        let hasTrack = !playing.track.isEmpty

        "AUDIO".draw(
            at: NSPoint(x: rect.minX + 8, y: rect.minY + 6),
            withAttributes: theme.type.attributes(8, color: palette.dim, kern: 0.4))

        if !hasTrack {
            "—".draw(
                at: NSPoint(x: rect.minX + 8, y: rect.midY - 4),
                withAttributes: theme.type.attributes(9, color: palette.dim))
            return
        }

        let artwork = view.artworkImage()
        let artSize = rect.height - 16
        var textX = rect.minX + 8
        var textWidth = rect.width - 20
        if let artwork {
            let frame = NSRect(x: rect.minX + 8, y: rect.midY - artSize / 2,
                               width: artSize, height: artSize)
            view.drawArtwork(artwork, in: frame,
                             border: palette.bezel.withAlphaComponent(0.8),
                             shadow: false)
            textX = frame.maxX + 10
            textWidth = rect.maxX - 12 - textX
        }

        let metaAttrs = theme.type.attributes(8, color: palette.text)
        let titleAttrs = theme.type.attributes(9, color: palette.text)
        let first = view.musicAlbumLine()
        if !first.isEmpty {
            view.drawMusicLine(first, x: textX, y: rect.midY - 10,
                               width: textWidth, attributes: metaAttrs)
        }
        let second = view.musicTitleLine()
        if !second.isEmpty {
            view.drawMusicLine(second, x: textX, y: rect.midY + 1,
                               width: textWidth, attributes: titleAttrs)
        }
    }
}
