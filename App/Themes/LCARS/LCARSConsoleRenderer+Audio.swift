//
//  LCARSConsoleRenderer%2BAudio.swift
//  HAL
//
//  La bande audio de la console LCARS, séparée du renderer principal.
//

import AppKit

@MainActor

extension LCARSConsoleRenderer {

    func drawAudioBand(in view: PanelView, rect: NSRect) {
        let theme = view.theme
        let palette = theme.palette

        lcarsFill(rect, palette.panelDeep, radius: 6)
        lcarsFill(NSRect(x: rect.minX, y: rect.minY, width: 6, height: rect.height),
                  palette.accentSoft, radius: 5, round: .left)

        let playing = view.snapshot.nowPlaying
        let hasTrack = !playing.track.isEmpty
        let label = hasTrack ? loc("NOW PLAYING") : loc("AUDIO LIBRARY")
        label.draw(at: NSPoint(x: rect.minX + 14, y: rect.minY + 6),
                   withAttributes: theme.type.attributes(
                       7, color: palette.accentSoft, bold: true, kern: 1.5))

        if !hasTrack {
            let attrs = theme.type.attributes(
                9, color: palette.dim, kern: 0.8)
            loc("NO PROGRAM SELECTED").draw(
                at: NSPoint(x: rect.minX + 14, y: rect.minY + 24),
                withAttributes: attrs)
            return
        }

        let artwork = view.artworkImage()
        let artSize = rect.height - 22
        var textX = rect.minX + 14
        var textWidth = rect.width - 28
        if let artwork {
            let frame = NSRect(x: rect.minX + 12, y: rect.minY + 16,
                               width: artSize, height: artSize)
            view.drawArtwork(artwork, in: frame,
                             border: palette.accentSoft.withAlphaComponent(0.6),
                             shadow: false)
            textX = frame.maxX + 10
            textWidth = rect.maxX - 8 - textX
        }

        let lines: [TextLine] = [
            TextLine(text: view.musicAlbumLine(), font: theme.type.font(8), color: palette.dim),
            TextLine(text: view.musicTitleLine(), font: theme.type.font(11, bold: true), color: palette.text)
        ]
        var lineY = rect.minY + 20
        for entry in lines {
            if !entry.text.isEmpty {
                view.drawMusicLine(entry.text, x: textX, y: lineY, width: textWidth,
                                   attributes: [.font: entry.font, .foregroundColor: entry.color])
            }
            lineY += 13
        }
    }
}
