//
//  HALRenderer+Audio.swift
//  HAL
//
//  La bande sonore du Discovery One, séparée du renderer principal.
//

import AppKit

@MainActor

extension HALRenderer {

    func drawAudioBand(in view: PanelView, rect: NSRect) {
        drawSpeakerGrille(in: rect, view: view)
        drawNowPlaying(in: rect, view: view)
    }

    /// Le panneau perforé : fond sombre, tous les trous poinçonnés en une
    /// seule passe de remplissage, puis le reflet discret sur leurs bords.
    private func drawSpeakerGrille(in rect: NSRect, view: PanelView) {
        let palette = view.theme.palette

        palette.panel.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()

        let holes = perforations(in: rect)
        NSColor(srgbRed: 0.02, green: 0.03, blue: 0.02, alpha: 1).setFill()
        holes.fill()
        NSColor(srgbRed: 0.24, green: 0.30, blue: 0.26, alpha: 0.55).setStroke()
        holes.lineWidth = 0.7
        holes.stroke()

        palette.bezel.setStroke()
        let border = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: 4, yRadius: 4)
        border.lineWidth = 1
        border.stroke()
    }

    /// Chemin unique contenant tous les trous de la grille.
    private func perforations(in rect: NSRect) -> NSBezierPath {
        let inset = rect.insetBy(dx: 7, dy: 7)
        let step: CGFloat = 8
        let hole: CGFloat = 2.6
        let path = NSBezierPath()
        var rowY = inset.minY + hole / 2
        while rowY <= inset.maxY - hole / 2 {
            var columnX = inset.minX + hole / 2
            while columnX <= inset.maxX - hole / 2 {
                path.appendOval(in: NSRect(x: columnX - hole / 2, y: rowY - hole / 2,
                                           width: hole, height: hole))
                columnX += step
            }
            rowY += step
        }
        return path
    }

    /// Pochette à gauche, morceau à droite. Sans pochette, les lignes se
    /// replient au centre de la bande.
    private func drawNowPlaying(in rect: NSRect, view: PanelView) {
        let playing = view.snapshot.nowPlaying
        let artwork = view.artworkImage()
        guard artwork != nil || !playing.track.isEmpty else { return }

        let palette = view.theme.palette
        let type = view.theme.type

        let artSize = rect.height - 12
        var textX = rect.midX
        var textWidth = rect.width / 2 - 14
        if let artwork {
            let frame = NSRect(x: rect.minX + 6, y: rect.midY - artSize / 2,
                               width: artSize, height: artSize)
            view.drawArtwork(artwork, in: frame, border: palette.bezel, shadow: true)
            textX = frame.maxX + 12
            textWidth = rect.maxX - 4 - textX
        }

        let firstLine = view.musicAlbumLine()
        let secondLine = view.musicTitleLine()
        let metaAttrs = type.attributes(9, color: palette.dim)
        var titleAttrs = type.attributes(11, color: palette.accent, bold: true)
        if let glow = type.glow(palette.accent, radius: 3) {
            titleAttrs[.shadow] = glow
        }

        let order: [(String, [NSAttributedString.Key: Any])] = [
            (firstLine, metaAttrs),
            (secondLine, titleAttrs)
        ]
        let lineHeight: CGFloat = 13
        var lineY = rect.midY - lineHeight * CGFloat(order.count) / 2

        for (line, attributes) in order {
            if !line.isEmpty {
                view.drawMusicLine(line, x: textX, y: lineY, width: textWidth,
                                   attributes: attributes)
            }
            lineY += lineHeight
        }
    }
}
