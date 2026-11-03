//
//  BladeRunnerRenderer+Rain.swift
//  HAL
//
//  La pluie de Los Angeles, novembre 2019 : le fond du panneau et ses
//  traînées de pluie, séparés du renderer principal.
//

import AppKit

@MainActor

extension BladeRunnerRenderer {

    // MARK: - Fond

    func drawBackground(in view: PanelView) {
        let theme = view.theme
        let palette = theme.palette
        let radius = theme.geometry.cornerRadius

        palette.background.setFill()
        NSBezierPath(roundedRect: view.bounds, xRadius: radius, yRadius: radius).fill()

        // Brume de la ville : rose en bas, cyan sur les bords.
        if let haze = NSGradient(starting: palette.panelDeep,
                                 ending: palette.accentSoft.withAlphaComponent(0.10)) {
            haze.draw(in: NSRect(x: 0, y: view.bounds.height * 0.55,
                                 width: view.bounds.width,
                                 height: view.bounds.height * 0.45),
                      angle: -90)
        }

        drawRain(in: view)
        drawGrid(in: view)

        palette.accentSoft.withAlphaComponent(0.32).setStroke()
        let border = NSBezierPath(roundedRect: view.bounds.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: radius, yRadius: radius)
        border.lineWidth = 1
        border.stroke()

        palette.accent.withAlphaComponent(0.10).setStroke()
        let inner = NSBezierPath(roundedRect: view.bounds.insetBy(dx: 3.5, dy: 3.5),
                                 xRadius: radius - 2, yRadius: radius - 2)
        inner.lineWidth = 0.6
        inner.stroke()
    }

    /// Pluie permanente : des traits courts, presque invisibles, qui
    /// tombent à des vitesses différentes. Elle reste sous le contenu.
    private func drawRain(in view: PanelView) {
        let palette = view.theme.palette
        let width = view.bounds.width
        let height = view.bounds.height
        let time = Date().timeIntervalSinceReferenceDate

        for index in 0..<58 {
            let seed = Double(index) * 0.6180339887
            let streakX = CGFloat(seed.truncatingRemainder(dividingBy: 1)) * width
            let speed = 34.0 + Double((index * 13) % 52)
            let span = Double(height + 80)
            let streakY = CGFloat((time * speed + Double(index) * 41)
                .truncatingRemainder(dividingBy: span)) - 40
            let length = CGFloat(9 + (index % 5) * 4)
            let color = index % 3 == 0 ? palette.accentSoft : palette.accent

            color.withAlphaComponent(0.035 + CGFloat(index % 4) * 0.012).setStroke()
            let streak = NSBezierPath()
            streak.move(to: NSPoint(x: streakX, y: streakY))
            streak.line(to: NSPoint(x: streakX - 2.5, y: streakY + length))
            streak.lineWidth = 0.7
            streak.stroke()
        }
    }

    /// Trame holographique discrète : la ville est quadrillée par ses
    /// propres réseaux.
    private func drawGrid(in view: PanelView) {
        let palette = view.theme.palette
        let path = NSBezierPath()
        var columnX: CGFloat = 0
        while columnX < view.bounds.width {
            path.move(to: NSPoint(x: columnX, y: 0))
            path.line(to: NSPoint(x: columnX, y: view.bounds.height))
            columnX += 34
        }
        var rowY: CGFloat = 0
        while rowY < view.bounds.height {
            path.move(to: NSPoint(x: 0, y: rowY))
            path.line(to: NSPoint(x: view.bounds.width, y: rowY))
            rowY += 30
        }
        palette.accent.withAlphaComponent(0.018).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

}

// MARK: - Formes

extension BladeRunnerRenderer {

    // MARK: - Formes

    /// Un rectangle à coins biseautés, la géométrie de la ville.
    func chamfered(_ rect: NSRect, cut: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        let edge = min(cut, min(rect.width, rect.height) / 2)
        path.move(to: NSPoint(x: rect.minX, y: rect.maxY - edge))
        path.line(to: NSPoint(x: rect.minX + edge, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX - edge, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - edge))
        path.line(to: NSPoint(x: rect.maxX, y: rect.minY + edge))
        path.line(to: NSPoint(x: rect.maxX - edge, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX + edge, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX, y: rect.minY + edge))
        path.close()
        return path
    }
}
