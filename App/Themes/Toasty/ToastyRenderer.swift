//
//  ToastyRenderer.swift
//  HAL
//
//  Le dessin Toasty : console d'atelier sombre, jauges à segments héritées
//  de Toasty, et l'œil rouge des Cylons qui balaye l'en-tête. Sobre partout
//  ailleurs — la menace se concentre sur un seul voyant.
//

import AppKit

@MainActor

final class ToastyRenderer: ThemeRenderer {

    // MARK: - Œil Cylon

    /// L'œil rouge de l'en-tête ; le dessin vit dans `ToasterLED`, avec
    /// la jauge à segments : le vocabulaire LED du grille-pain.
    private func drawCylonEye(in rect: NSRect, segments: Int,
                              litColor: NSColor, baseColor: NSColor) {
        ToasterLED.eye(in: rect, segments: segments, phase: Self.cylonPhase(),
                       litColor: litColor, baseColor: baseColor)
    }

    /// Phase du balayage : l'œil n'avance qu'aux rafraîchissements du
    /// panneau (un tick toutes les 2 s), à la manière des LED-mètres qui
    /// avancent par crans. Un balayage fluide imposerait une boucle de
    /// rafraîchissement permanente, cher pour un clin d'œil.
    static func cylonPhase() -> Int {
        let halfPeriod = 12
        let step = Int(Date().timeIntervalSinceReferenceDate / 0.6)
        let triangle = step % (halfPeriod * 2)
        return triangle < halfPeriod ? triangle : halfPeriod * 2 - triangle - 1
    }

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
        let title = "Battlestar Galactica"
        title.draw(at: NSPoint(x: textX, y: 20),
                   withAttributes: theme.type.attributes(15, color: palette.text,
                                                         bold: true, kern: 0.4))

        let subtitle = "COLONIAL FLEET · BS-75"
        subtitle.draw(at: NSPoint(x: textX, y: 40),
                      withAttributes: theme.type.attributes(9, color: palette.dim, kern: 0.6))

        // La ligne du jour : date longue dans la langue de l'application,
        // quelques espaces, puis l'heure. L'heure a quitté le centre du
        // panneau : c'est le jour qui la porte désormais.
        let dayLine = [Self.localizedLongDate(from: view.snapshot.date),
                       Self.clock.string(from: view.snapshot.date)].joined(separator: "      ")
        dayLine.draw(at: NSPoint(x: textX, y: 60),
                     withAttributes: theme.type.attributes(10, color: palette.text))

        let frame = theme.geometry.headerTipRect(in: view.bounds.width)
        let eyeRect = NSRect(x: frame.minX, y: frame.minY + frame.height / 2 - 5,
                             width: frame.width, height: 10)
        drawCylonEye(in: eyeRect, segments: 7, litColor: palette.accent, baseColor: palette.accent)
    }

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// La date longue localisée, première lettre capitalisée. Le formateur
    /// coûte cher à fabriquer : il est conservé d'un dessin à l'autre et
    /// refait seulement quand la langue change.
    private static var longDateLocale = Localization.current
    private static var longDate = ToastyRenderer.makeLongDate()

    private static func makeLongDate() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Localization.current)
        formatter.dateStyle = .full
        return formatter
    }

    private static func localizedLongDate(from date: Date) -> String {
        if longDateLocale != Localization.current {
            longDate = makeLongDate()
            longDateLocale = Localization.current
        }
        let raw = longDate.string(from: date)
        return String(raw.prefix(1)).uppercased() + String(raw.dropFirst())
    }

    // MARK: - Onglets

    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        for (entry, rect) in tabRects {
            let active = entry == view.tab
            let path = NSBezierPath(rect: rect)

            palette.panelDeep.withAlphaComponent(active ? 1.0 : 0.6).setFill()
            path.fill()

            if active {
                palette.accent.setFill()
                NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY,
                                          width: 2, height: rect.height)).fill()
            } else {
                palette.bezel.withAlphaComponent(0.5).setStroke()
                path.lineWidth = 1
                path.stroke()
            }

            let attrs = theme.type.attributes(
                9, color: active ? palette.text : palette.dim, kern: 0.4)
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

    /// Jauge à segments : l'identité de Toasty, gardée telle quelle. Les
    /// segments s'allument par crans — pas de barre lisse, pas de dégradé.
    private func drawSegmentGauge(in rect: NSRect, fraction: Double,
                                  color: NSColor, off: NSColor) {
        ToasterLED.gauge(in: rect, fraction: fraction, color: color, off: off)
    }

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

        let labelAttrs = theme.type.attributes(9, color: palette.dim, kern: 0.4)
        label.draw(at: NSPoint(x: rect.minX + 8, y: rect.maxY - 14),
                   withAttributes: labelAttrs)

        let valueColor = hot ? palette.danger : palette.text
        let valueAttrs = theme.type.attributes(small ? 11 : 13, color: valueColor)
        value.draw(at: NSPoint(x: rect.minX + 8, y: rect.maxY - 33),
                   withAttributes: valueAttrs)

        let subAttrs = theme.type.attributes(8, color: palette.dim)
        sub.draw(at: NSPoint(x: rect.minX + 8, y: rect.maxY - 46),
                 withAttributes: subAttrs)

        let gauge = NSRect(x: rect.minX + 8, y: rect.minY + 8,
                           width: rect.width - 16, height: 3)
        drawSegmentGauge(in: gauge, fraction: fraction,
                         color: accent, off: palette.bezel.withAlphaComponent(0.35))
    }

    // MARK: - Alertes

    func drawAlert(in view: PanelView, spec: AlertSpec) {
        let rect = spec.rect
        let message = spec.message
        let visible = spec.visible
        let theme = view.theme
        let palette = theme.palette

        palette.panel.withAlphaComponent(0.95).setFill()
        NSBezierPath(rect: rect).fill()

        palette.danger.withAlphaComponent(visible ? 0.9 : 0.4).setStroke()
        let border = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        // Aux postes de combat : le message du thème, ou l'état seul.
        let text = message.isEmpty
            ? (visible ? "ACTION STATIONS" : "STAND BY")
            : (visible ? message : "STAND BY")
        let attrs = theme.type.attributes(9, color: visible ? palette.danger : palette.dim,
                                          kern: 0.4)
        let size = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (view.bounds.width - size.width) / 2,
                              y: rect.minY + 6),
                  withAttributes: attrs)
    }

    // MARK: - Scanlines

    func drawScanlines(in view: PanelView) {
        // Sobre : rien. La menace est sur l'œil, pas sur le papier de verre.
    }

    // MARK: - Bande son

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
        // Même marge que HAL (−12) : pochette de 44 px quand la bande fait
        // ses 56 px, identique à la bande son du Discovery One.
        let artSize = rect.height - 12
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

        let metaAttrs = theme.type.attributes(8, color: palette.dim)
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
                let attrs = theme.type.attributes(8, color: palette.dim, kern: 0.3)
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
        // L'airlock : rouge quand il est actionnable, éteint sinon. On ne
        // rejette rien par le sas sans autorisation.
        let tint = enabled ? palette.accent : palette.dim
        tint.withAlphaComponent(enabled ? 0.8 : 0.4).setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs = theme.type.attributes(8, color: enabled ? palette.text : palette.dim,
                                          kern: 0.3)
        let width = title.size(withAttributes: attrs).width
        title.draw(at: NSPoint(x: buttonRect.midX - width / 2,
                               y: buttonRect.minY + 3),
                   withAttributes: attrs)
    }
}
