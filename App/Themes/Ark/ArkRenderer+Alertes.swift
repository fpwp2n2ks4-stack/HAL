//
//  ArkRenderer+Alertes.swift
//  HAL
//
//  Les alertes, la trame et la bande son d Ark One, séparées du renderer
//  principal.
//

import AppKit

@MainActor

extension ArkRenderer {

    // MARK: - Alertes

    func drawAlert(in view: PanelView, spec: AlertSpec) {
        let rect = spec.rect
        let kind = spec.kind
        let label = spec.label
        let message = spec.message
        let visible = spec.visible
        let theme = view.theme
        let palette = theme.palette
        let tint = kind == .cpu ? palette.danger : palette.warning
        let path = chamferedPath(rect, cut: 5)

        palette.screen.withAlphaComponent(0.96).setFill()
        path.fill()
        stroke(path, tint.withAlphaComponent(visible ? 0.95 : 0.35))

        // Triangle d'alerte, à gauche.
        let triangle = NSBezierPath()
        triangle.move(to: NSPoint(x: rect.minX + 13, y: rect.midY - 6))
        triangle.line(to: NSPoint(x: rect.minX + 20, y: rect.midY + 6))
        triangle.line(to: NSPoint(x: rect.minX + 6, y: rect.midY + 6))
        triangle.close()
        tint.withAlphaComponent(visible ? 0.9 : 0.3).setFill()
        triangle.fill()

        guard visible else { return }

        let text = label.isEmpty ? message : "\(label) · \(message)"
        let attrs = theme.type.attributes(9, color: tint, bold: true, kern: 1.0)
        truncated(text, toWidth: rect.width - 34, attributes: attrs)
            .draw(at: NSPoint(x: rect.minX + 27, y: rect.minY + 6),
                  withAttributes: attrs)
    }

    // MARK: - Trame

    func drawScanlines(in view: PanelView) {
        // Trame d'affichage embarqué : horizontale, très pâle, jamais un
        // masque CRT.
        view.theme.palette.panelDeep.withAlphaComponent(0.11).setFill()
        var lineY: CGFloat = 0
        while lineY < view.bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: lineY,
                                      width: view.bounds.width, height: 1)).fill()
            lineY += 4
        }

        // Équerres de visée, aux quatre coins utiles.
        let palette = view.theme.palette
        let corners = NSBezierPath()
        let inset: CGFloat = 3
        let length: CGFloat = 8
        corners.move(to: NSPoint(x: inset, y: inset + length))
        corners.line(to: NSPoint(x: inset, y: inset))
        corners.line(to: NSPoint(x: inset + length, y: inset))
        corners.move(to: NSPoint(x: view.bounds.width - inset - length, y: inset))
        corners.line(to: NSPoint(x: view.bounds.width - inset, y: inset))
        corners.line(to: NSPoint(x: view.bounds.width - inset, y: inset + length))
        corners.move(to: NSPoint(x: inset, y: view.bounds.height - inset - length))
        corners.line(to: NSPoint(x: inset, y: view.bounds.height - inset))
        corners.line(to: NSPoint(x: inset + length, y: view.bounds.height - inset))
        corners.move(to: NSPoint(x: view.bounds.width - inset - length,
                                 y: view.bounds.height - inset))
        corners.line(to: NSPoint(x: view.bounds.width - inset,
                                 y: view.bounds.height - inset))
        corners.line(to: NSPoint(x: view.bounds.width - inset,
                                 y: view.bounds.height - inset - length))
        stroke(corners, palette.accent.withAlphaComponent(0.35))
    }

    // MARK: - Bande son

    func drawAudioBand(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let path = chamferedPath(rect, cut: 6)

        palette.screen.setFill()
        path.fill()
        stroke(path, palette.bezel.withAlphaComponent(0.9))

        let labelAttrs = theme.type.attributes(7, color: palette.dim,
                                               bold: true, kern: 1.6)
        let label = "AUDIO LOG"
        let labelWidth = label.size(withAttributes: labelAttrs).width
        label.draw(at: NSPoint(x: rect.maxX - 9 - labelWidth, y: rect.maxY - 13),
                   withAttributes: labelAttrs)

        let playing = view.snapshot.nowPlaying
        guard !playing.track.isEmpty else {
            "NO SIGNAL".draw(at: NSPoint(x: rect.minX + 9, y: rect.midY),
                             withAttributes: theme.type.attributes(
                                9, color: palette.dim.withAlphaComponent(0.7),
                                bold: true, kern: 1.4))
            return
        }

        drawNowPlaying(in: rect, view: view)
        drawEqualizer(in: rect, palette: palette)
    }

    /// Pochette et lignes du morceau en cours.
    private func drawNowPlaying(in rect: NSRect, view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let artwork = view.artworkImage()
        let artSize = rect.height - 16
        var textX = rect.minX + 9
        var textWidth = rect.width - 52

        if let artwork {
            let frame = NSRect(x: rect.minX + 9, y: rect.midY - artSize / 2,
                               width: artSize, height: artSize)
            view.drawArtwork(artwork, in: frame,
                             border: palette.accent.withAlphaComponent(0.55),
                             shadow: false)
            textX = frame.maxX + 9
            textWidth = rect.maxX - 34 - textX
        }

        let metaAttrs = theme.type.attributes(8, color: palette.dim, kern: 0.6)
        let titleAttrs = theme.type.attributes(10, color: palette.accent,
                                               bold: true, kern: 0.8)

        let first = view.musicAlbumLine()
        if !first.isEmpty {
            view.drawMusicLine(first, x: textX, y: rect.midY - 10,
                               width: max(0, textWidth), attributes: metaAttrs)
        }
        let second = view.musicTitleLine()
        if !second.isEmpty {
            view.drawMusicLine(second, x: textX, y: rect.midY + 2,
                               width: max(0, textWidth), attributes: titleAttrs)
        }
    }

    /// Petit égaliseur fixe : il indique que la bande est active sans
    /// prétendre mesurer le son.
    private func drawEqualizer(in rect: NSRect, palette: ThemePalette) {
        let levels: [CGFloat] = [4, 9, 6, 13, 8, 11]
        let barX = rect.maxX - 24
        for (index, level) in levels.enumerated() {
            let height = min(rect.height - 18, level * 2.4)
            palette.accent.withAlphaComponent(0.55).setFill()
            NSBezierPath(rect: NSRect(x: barX + CGFloat(index) * 3,
                                      y: rect.midY + 6 - height,
                                      width: 2, height: height)).fill()
        }
    }
}

// MARK: - Étoiles

/// Une étoile fixe du ciel d'Ark, en coordonnées relatives au panneau.
struct Star {
    let atX: CGFloat
    let atY: CGFloat
    let size: CGFloat
    let alpha: CGFloat
}

// MARK: - En-tête

extension ArkRenderer {

    // MARK: - En-tête

    func drawHeader(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let padding = theme.geometry.padding
        let tip = theme.geometry.headerTipRect(in: view.bounds.width)

        // Titre et immatriculation.
        let titleAttrs = theme.type.attributes(21, color: palette.accent, bold: true,
                                               kern: 2.0)
        "ARK ONE".draw(at: NSPoint(x: padding, y: 10), withAttributes: titleAttrs)

        let subtitleAttrs = theme.type.attributes(8, color: palette.dim,
                                                  bold: true, kern: 1.4)
        truncated("COLONY VESSEL · ARK PROGRAM · PROXIMA CENTAURI B",
                  toWidth: view.bounds.width - padding * 2 - 110,
                  attributes: subtitleAttrs)
            .draw(at: NSPoint(x: padding, y: 38), withAttributes: subtitleAttrs)

        // Horloge de bord.
        let clockFmt = DateFormatter()
        clockFmt.dateFormat = "EEEE d MMMM yyyy · HH:mm:ss"
        clockFmt.locale = Locale(identifier: Localization.current)
        let clock = clockFmt.string(from: view.snapshot.date)
        let clockAttrs = theme.type.attributes(8, color: palette.dim.withAlphaComponent(0.85),
                                               kern: 0.8)
        truncated(clock.uppercased(with: Locale(identifier: Localization.current)),
                  toWidth: view.bounds.width - padding * 2 - 110,
                  attributes: clockAttrs)
            .draw(at: NSPoint(x: padding, y: 56), withAttributes: clockAttrs)

        // Écusson de mission, sous l'infobulle de l'en-tête.
        drawMissionCrest(in: tip, view: view)

        // Filet vertical, à gauche de l'écusson : il sépare le bloc
        // d'identification de la marque de mission sans couper les onglets.
        let dividerX = tip.minX - 18
        if dividerX > padding {
            let divider = NSBezierPath()
            divider.move(to: NSPoint(x: dividerX, y: 14))
            divider.line(to: NSPoint(x: dividerX, y: tip.maxY - 2))
            stroke(divider, palette.bezel.withAlphaComponent(0.75))
        }
    }

    /// L'écusson de mission : double cercle, coque en arc, vecteur de
    /// trajectoire, numéro de coque — le blason du programme Ark.
    private func drawMissionCrest(in tip: NSRect, view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let center = NSPoint(x: tip.midX, y: tip.midY)
        let outer = NSBezierPath(ovalIn: NSRect(x: center.x - 26, y: center.y - 26,
                                                width: 52, height: 52))
        stroke(outer, palette.bezel.withAlphaComponent(0.9), width: 1)
        let inner = NSBezierPath(ovalIn: NSRect(x: center.x - 21, y: center.y - 21,
                                                width: 42, height: 42))
        stroke(inner, palette.accent.withAlphaComponent(0.35))

        let hull = NSBezierPath()
        hull.appendArc(withCenter: center, radius: 17,
                       startAngle: 200, endAngle: 340)
        stroke(hull, palette.accent, width: 2)

        let vector = NSBezierPath()
        vector.move(to: NSPoint(x: center.x - 11, y: center.y + 9))
        vector.line(to: NSPoint(x: center.x + 12, y: center.y - 7))
        stroke(vector, palette.accentSoft.withAlphaComponent(0.8), width: 1)

        "01".draw(at: NSPoint(x: center.x - 7, y: center.y - 6),
                  withAttributes: theme.type.attributes(9, color: palette.text,
                                                        bold: true, kern: 1.2))

        palette.glass.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x + 13, y: center.y + 14,
                                    width: 3, height: 3)).fill()
    }
}
