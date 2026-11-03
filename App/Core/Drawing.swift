//
//  Drawing.swift
//  HAL
//
//  Petites primitives de texte communes aux renderers : troncature à la
//  largeur et alignement à droite. Elles vivent dans le noyau parce que
//  les extensions de dessin y font appel sans connaître le thème.
//

import AppKit

/// Chaîne coupée à la largeur donnée, avec points de suspension.
///
/// La mesure se fait sur la chaîne entière puis rognée caractère par
/// caractère : le texte au complet sert de clé de mesure, donc pas de
/// « … » qui danse d'une frame à l'autre faute de contexte.
func truncated(_ string: String, toWidth width: CGFloat,
               attributes: [NSAttributedString.Key: Any]) -> String {
    guard string.size(withAttributes: attributes).width > width else { return string }
    let ellipsis = "…"
    let ellipsisWidth = ellipsis.size(withAttributes: attributes).width
    var cut = string
    while !cut.isEmpty,
          cut.size(withAttributes: attributes).width + ellipsisWidth > width {
        cut.removeLast()
    }
    return cut + ellipsis
}

/// Variante qui ne mesure que la police : suffisante quand le crénage est
/// nul ou négligeable.
func truncated(_ string: String, toWidth width: CGFloat, font: NSFont) -> String {
    truncated(string, toWidth: width, attributes: [.font: font])
}

/// Texte aligné sur son bord droit (`rowY` = ordonnée de la ligne).
func drawRight(_ text: String, at rowY: CGFloat, rightEdge: CGFloat,
               font: NSFont, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let width = text.size(withAttributes: attrs).width
    let textX = rightEdge - width
    guard textX >= 0 else { return }
    text.draw(at: NSPoint(x: textX, y: rowY), withAttributes: attrs)
}
