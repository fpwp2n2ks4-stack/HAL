//
//  PanelView+Audio.swift
//  HAL
//
//  La bande son du panneau, sous la dernière rangée d'écrans. Le noyau
//  fournit le rectangle, la pochette décodée et le générique du morceau ;
//  le thème compose le reste (grille perforée de HAL, bibliothèque LCARS).
//
//  Le lecteur lui-même est du côté des capteurs (`NowPlayingReader`) :
//  cette extension ne fait que dessiner ce qui arrive dans le snapshot.
//

import AppKit

extension PanelView {

    // MARK: - Géométrie

    /// Rectangle de la bande son.
    ///
    /// Partagé entre le dessin et les zones d'extinction finale : les deux
    /// doivent coïncider au pixel près, sinon l'écran qu'on éteint n'est
    /// pas celui qu'on a allumé.
    func speakerBandRect(at rowY: CGFloat) -> NSRect {
        let height = min(theme.geometry.speakerBandHeight, panelHeight - rowY - 10)
        // Une bande trop mince dessinerait des ovales à peine visibles :
        // autant n'en rien faire du tout.
        guard height > 20 else { return .zero }
        return NSRect(x: contentX, y: rowY + 2, width: contentW, height: height)
    }

    // MARK: - Dessin

    func drawAudioBand(at rowY: CGFloat) {
        let rect = speakerBandRect(at: rowY)
        guard !rect.isEmpty else { return }
        theme.renderer.drawAudioBand(in: self, rect: rect)
    }

    // MARK: - Contenu partagé

    /// « ARTISTE · ALBUM · ANNÉE », chaque morceau omis s'il manque.
    func musicAlbumLine() -> String {
        let playing = snapshot.nowPlaying
        var parts: [String] = []
        if !playing.artist.isEmpty { parts.append(playing.artist) }
        if !playing.album.isEmpty { parts.append(playing.album) }
        if playing.year > 0 { parts.append("\(playing.year)") }
        return parts.joined(separator: " · ")
            .uppercased(with: Locale(identifier: Localization.current))
    }

    /// Titre du morceau, en majuscules, dans la locale de l'app.
    func musicTitleLine() -> String {
        snapshot.nowPlaying.track
            .uppercased(with: Locale(identifier: Localization.current))
    }

    /// Une ligne de texte du morceau, coupée à la largeur disponible.
    func drawMusicLine(_ text: String, x atX: CGFloat, y atY: CGFloat, width: CGFloat,
                       attributes: [NSAttributedString.Key: Any]) {
        let displayed = truncated(text, toWidth: width, attributes: attributes)
        guard !displayed.isEmpty else { return }
        NSAttributedString(string: displayed, attributes: attributes)
            .draw(at: NSPoint(x: atX, y: atY))
    }

    /// Pochette décodée, en cache : `Data` → `NSImage` coûte un décodage
    /// JPEG, inutile à chaque frame.
    func artworkImage() -> NSImage? {
        guard let data = snapshot.nowPlaying.artworkData, !data.isEmpty else {
            artworkCache = nil
            return nil
        }
        if let cached = artworkCache, cached.data == data { return cached.image }
        guard let image = NSImage(data: data) else {
            artworkCache = nil
            return nil
        }
        artworkCache = (data, image)
        return image
    }

    /// Pochette : contenue dans son carré, jamais déformée, détachée du
    /// fond par un cadre aux couleurs du thème.
    func drawArtwork(_ image: NSImage, in frame: NSRect,
                     border: NSColor, shadow: Bool) {
        let size = image.size
        guard size.width > 1, size.height > 1 else { return }

        // Ajustement « contenir » : l'image reste entière, dans le plus
        // grand rectangle qui lui tient.
        let scale = min(frame.width / size.width, frame.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        let target = NSRect(x: frame.midX - width / 2, y: frame.midY - height / 2,
                            width: width, height: height)

        let drop = NSShadow()
        drop.shadowColor = NSColor.black.withAlphaComponent(0.75)
        drop.shadowBlurRadius = 5
        drop.shadowOffset = .zero

        NSGraphicsContext.saveGraphicsState()
        if shadow { drop.set() }
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: target, from: .zero, operation: .sourceOver,
                   fraction: 1, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()

        border.setStroke()
        let path = NSBezierPath(rect: target.insetBy(dx: -1.5, dy: -1.5))
        path.lineWidth = 1
        path.stroke()
    }
}
