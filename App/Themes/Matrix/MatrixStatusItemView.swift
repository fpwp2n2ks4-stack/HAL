//
//  MatrixStatusItemView.swift
//  HAL
//
//  Barre de menus Matrix : texte vert phosphore.
//
import AppKit

final class MatrixStatusItemView: StatusItemView {

    /// Quand la valeur est masquée (îlot au repos, à côté de la caméra),
    /// le thème garde une petite signature : sans elle, Matrix n'aurait
    /// aucun insigne et l'aile resterait vide.
    private let glyph = "101"

    override func draw(_ dirtyRect: NSRect) {
        let critical = isCritical
        let palette = theme.palette
        let shown = readout
        let text = shown.isEmpty ? glyph : shown
        let color = critical ? palette.danger : palette.accent
        let font = readoutFont
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        if let glow = theme.type.glow(color, radius: 3) {
            attrs[.shadow] = glow
        }
        text.draw(at: NSPoint(x: shown.isEmpty ? 2 : 4,
                              y: (bounds.height - font.pointSize) / 2),
                  withAttributes: attrs)
    }

    override var intrinsicContentSize: NSSize {
        let text = readout
        let font = readoutFont
        if text.isEmpty {
            return NSSize(width: glyph.size(withAttributes: [.font: font]).width + 4,
                          height: 16)
        }
        let width = text.size(withAttributes: [.font: font]).width
        return NSSize(width: width + 8, height: 16)
    }
}
