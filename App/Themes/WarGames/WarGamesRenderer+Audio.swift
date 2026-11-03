//
//  WarGamesRenderer+Audio.swift
//  HAL
//
//  Le balayage et la bande audio du WOPR, séparée du renderer principal.
//

import AppKit

@MainActor

extension WarGamesRenderer {

    // MARK: - Scanlines

    func drawScanlines(in view: PanelView) {
        let palette = view.theme.palette

        NSColor.black.withAlphaComponent(0.17).setFill()
        var lineY: CGFloat = 0
        while lineY < view.bounds.height {
            NSBezierPath(rect: NSRect(x: 0, y: lineY,
                                      width: view.bounds.width, height: 1)).fill()
            lineY += 3
        }

        if let vignette = NSGradient(colors: [
            .clear,
            NSColor.black.withAlphaComponent(0.42)
        ]) {
            vignette.draw(in: view.bounds.insetBy(dx: 2, dy: 2),
                          relativeCenterPosition: .zero)
        }

        // Bande de rafraîchissement : très lente, très pâle.
        let time = Date().timeIntervalSinceReferenceDate
        let sweepY = CGFloat((time * 22).truncatingRemainder(
            dividingBy: Double(view.bounds.height)))
        palette.accent.withAlphaComponent(0.025).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: sweepY,
                                  width: view.bounds.width, height: 6)).fill()
    }

    // MARK: - Bande son

    func drawAudioBand(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)

        palette.screen.setFill()
        path.fill()
        palette.accent.withAlphaComponent(0.45).setStroke()
        path.lineWidth = 1
        path.stroke()

        let hasTrack = !view.snapshot.nowPlaying.track.isEmpty
        drawFeedHeader(in: rect, view: view, hasTrack: hasTrack)

        if !hasTrack {
            drawNoProgram(in: rect, view: view)
            return
        }
        drawNowPlaying(in: rect, view: view)
    }

    /// L'entête du flux : « AUDIO FEED » à gauche, l'état à droite.
    private func drawFeedHeader(in rect: NSRect, view: PanelView, hasTrack: Bool) {
        let theme = view.theme
        let palette = theme.palette

        "AUDIO FEED".draw(
            at: NSPoint(x: rect.minX + 8, y: rect.minY + 5),
            withAttributes: theme.type.attributes(
                7.5, color: palette.accent, bold: true, kern: 1.4))
        let state = hasTrack ? "NOW PLAYING" : "NO SIGNAL"
        let stateAttrs = theme.type.attributes(
            7, color: hasTrack ? palette.accentSoft : palette.dim,
            bold: true, kern: 1.1)
        let stateWidth = state.size(withAttributes: stateAttrs).width
        state.draw(at: NSPoint(x: rect.maxX - 8 - stateWidth, y: rect.minY + 5),
                   withAttributes: stateAttrs)
    }

    /// Sans morceau, le flux reste ouvert : la note le dit, la forme
    /// d'onde continue de tourner, éteinte.
    private func drawNoProgram(in rect: NSRect, view: PanelView) {
        let palette = view.theme.palette

        "> NO PROGRAM SELECTED".draw(
            at: NSPoint(x: rect.minX + 8, y: rect.minY + 25),
            withAttributes: view.theme.type.attributes(
                9, color: palette.dim, kern: 0.4))
        drawWaveform(in: NSRect(x: rect.maxX - 58, y: rect.minY + 18,
                                width: 44, height: 28),
                     color: palette.accent.withAlphaComponent(0.18))
    }

    /// Pochette à gauche, lignes du morceau au centre, forme d'onde à
    /// droite : le programme en cours.
    private func drawNowPlaying(in rect: NSRect, view: PanelView) {
        let theme = view.theme
        let palette = theme.palette

        let artwork = view.artworkImage()
        let artSize = rect.height - 24
        var textX = rect.minX + 8
        var textWidth = rect.width - 76
        if let artwork {
            let frame = NSRect(x: rect.minX + 8, y: rect.minY + 16,
                               width: artSize, height: artSize)
            view.drawArtwork(artwork, in: frame,
                             border: palette.accent.withAlphaComponent(0.7),
                             shadow: true)
            textX = frame.maxX + 10
            textWidth = rect.maxX - 64 - textX
        }

        let lines: [TextLine] = [
            TextLine(text: view.musicAlbumLine(), font: theme.type.font(7.5), color: palette.dim),
            TextLine(text: view.musicTitleLine(), font: theme.type.font(10, bold: true), color: palette.text)
        ]
        var lineY = rect.minY + 19
        for entry in lines {
            if !entry.text.isEmpty {
                view.drawMusicLine(entry.text, x: textX, y: lineY, width: textWidth,
                                   attributes: [.font: entry.font, .foregroundColor: entry.color])
            }
            lineY += 13
        }

        drawWaveform(in: NSRect(x: rect.maxX - 58, y: rect.minY + 18,
                                width: 44, height: 28),
                     color: palette.accent)
    }

    /// Forme d'onde en barres pleines, comme un analyseur de modem.
    private func drawWaveform(in rect: NSRect, color: NSColor) {
        let bars = 12
        let gap: CGFloat = 2
        let barWidth = max(1, (rect.width - gap * CGFloat(bars - 1))
            / CGFloat(bars))
        let time = Date().timeIntervalSinceReferenceDate

        for index in 0..<bars {
            let phase = time * 2.2 + Double(index) * 0.8
            let level = sin(phase) * 0.5 + 0.5
            let height = 2 + CGFloat(level) * (rect.height - 3)
            let barX = rect.minX + CGFloat(index) * (barWidth + gap)
            color.withAlphaComponent(0.18 + CGFloat(level) * 0.35).setFill()
            NSBezierPath(rect: NSRect(x: barX, y: rect.maxY - height,
                                      width: barWidth, height: height)).fill()
        }
    }
}
