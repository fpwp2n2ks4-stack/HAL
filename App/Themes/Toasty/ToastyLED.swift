//
//  ToastyLED.swift
//  HAL
//
//  Le vocabulaire LED du grille-pain Toasty : l'œil Cylon et les
//  jauges à segments. Fichier propre, hors du renderer.
//

import AppKit

// MARK: - Le vocabulaire LED du grille-pain

/// Les LED de Toasty : l'œil rouge qui balaye et les jauges à segments.
/// Hors de la classe du renderer pour garder le dessin de panneau lisible,
/// au niveau du fichier où vit le seul style du thème.
enum ToasterLED {

    /// L'œil : une lentille chromée, des segments rouges éteints presque
    /// invisibles, un seul allumé qui fait l'aller-retour.
    static func eye(in rect: NSRect, segments: Int, phase: Int,
                    litColor: NSColor, baseColor: NSColor) {
        let chrome = NSColor(srgbRed: 0.588, green: 0.561, blue: 0.518, alpha: 1)
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: rect.height / 2,
                     yRadius: rect.height / 2).setClip()

        chrome.setFill()
        NSBezierPath(rect: rect).fill()
        let inner = rect.insetBy(dx: 2, dy: 2)
        baseColor.withAlphaComponent(0.25).setFill()
        NSBezierPath(roundedRect: inner, xRadius: inner.height / 2,
                      yRadius: inner.height / 2).fill()

        let gap: CGFloat = 3
        let width = (inner.width - gap * CGFloat(segments - 1)) / CGFloat(segments)
        let lit = phase % segments
        for index in 0..<segments {
            let segment = NSRect(x: inner.minX + CGFloat(index) * (width + gap),
                                 y: inner.minY,
                                 width: width,
                                 height: inner.height)
            (index == lit ? litColor : baseColor.withAlphaComponent(0.18)).setFill()
            NSBezierPath(rect: segment).fill()
        }

        // Retire le masque posé plus haut : la fuite de clipping est la
        // punition classique de qui dessine un œil en bac à sable.
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    /// La jauge : des segments qui s'allument par crans — pas de barre
    /// lisse, pas de dégradé. `fraction` se lit en crans allumés.
    static func gauge(in rect: NSRect, fraction: Double,
                      color: NSColor, off: NSColor) {
        let segments = 12
        let gap: CGFloat = 2
        let width = (rect.width - gap * CGFloat(segments - 1)) / CGFloat(segments)
        let lit = Int((max(0, min(1, fraction)) * Double(segments)).rounded(.up))

        off.setFill()
        NSBezierPath(rect: rect).fill()

        for index in 0..<segments where index < lit {
            let segment = NSRect(x: rect.minX + CGFloat(index) * (width + gap),
                                 y: rect.minY,
                                 width: width,
                                 height: rect.height)
            color.setFill()
            NSBezierPath(rect: segment).fill()
        }
    }
}
