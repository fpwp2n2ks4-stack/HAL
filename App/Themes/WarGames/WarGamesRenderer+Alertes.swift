//
//  WarGamesRenderer+Alertes.swift
//  HAL
//
//  Les alertes du WOPR, séparées du renderer principal.
//

import AppKit

@MainActor

extension WarGamesRenderer {

    // MARK: - Alertes

    func drawAlert(in view: PanelView, spec: AlertSpec) {
        let rect = spec.rect
        let kind = spec.kind
        let label = spec.label
        let message = spec.message
        let visible = spec.visible
        let theme = view.theme
        let palette = theme.palette
        let accent = kind == .cpu ? palette.danger : palette.warning
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)

        if visible {
            accent.withAlphaComponent(0.92).setFill()
            path.fill()
        } else {
            palette.screen.setFill()
            path.fill()
        }

        accent.withAlphaComponent(visible ? 1 : 0.45).setStroke()
        path.lineWidth = 1
        path.stroke()

        let textColor = visible ? palette.background : accent
        let left = label.isEmpty ? "!!" : "!! \(label)"
        let leftAttrs = theme.type.attributes(
            9, color: textColor, bold: true, kern: 1.4)
        truncated(left, toWidth: 130, attributes: leftAttrs)
            .draw(at: NSPoint(x: rect.minX + 8, y: rect.minY + 6),
                  withAttributes: leftAttrs)

        let messageAttrs = theme.type.attributes(
            7.5, color: textColor, bold: true, kern: 0.6)
        truncated(message, toWidth: rect.width - 160, attributes: messageAttrs)
            .draw(at: NSPoint(x: rect.minX + 142, y: rect.minY + 7),
                  withAttributes: messageAttrs)

        // Le témoin qui bat, à droite.
        if visible {
            palette.background.withAlphaComponent(0.85).setFill()
            NSBezierPath(rect: NSRect(x: rect.maxX - 18, y: rect.minY + 7,
                                      width: 7, height: 7)).fill()
        } else {
            accent.withAlphaComponent(0.35).setStroke()
            NSBezierPath(rect: NSRect(x: rect.maxX - 18, y: rect.minY + 7,
                                      width: 7, height: 7)).stroke()
        }
    }

}
