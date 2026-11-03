//
//  NotchGeometry.swift
//  HAL
//
//  Mesures de l'encoche. Le noyau n'invente rien : macOS expose la largeur
//  utile de part et d'autre du cran (`auxiliaryTopLeftArea` /
//  `auxiliaryTopRightArea`) et sa hauteur (`safeAreaInsets.top`). La largeur
//  du cran est ce qui reste entre les deux.
//
//  Aucune fenêtre n'est dessinée « dans » l'encoche : c'est un trou physique.
//  L'îlot se contente de prolonger le noir vers le bas, exactement comme le
//  ferait une Dynamic Island.
//

import AppKit

struct NotchGeometry {

    /// Marge de chaque côté du cran, au repos. Elle ne dessine plus de
    /// noir : elle laisse juste assez de place à la marque du thème, collée
    /// au bord gauche du cran, et à sa zone de clic. Assez étroite pour ne
    /// jamais approcher les titres de menus.
    static let wingWidth: CGFloat = 28

    let screen: NSScreen
    let screenFrame: NSRect

    /// Vrai si l'écran a un cran physique.
    let hasNotch: Bool

    /// Largeur du cran, marge de recouvrement comprise.
    let notchWidth: CGFloat

    /// Hauteur du cran, plus un point de recouvrement pour masquer la jointure.
    let notchHeight: CGFloat

    /// L'écran qui porte l'îlot : celui du cran s'il existe, sinon le
    /// principal. Sur un écran sans cran, on utilise quand même l'écran principal.
    static func preferred() -> NotchGeometry? {
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
            ?? NSScreen.main
        guard let screen = screen else {
            return nil
        }
        return NotchGeometry(screen: screen)
    }

    /// Force la détection d'une encoche (pour les tests ou fallback)
    static func force() -> NotchGeometry {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        return NotchGeometry(screen: screen)
    }

    init(screen: NSScreen) {
        self.screen = screen
        self.screenFrame = screen.frame

        let safeTop = screen.safeAreaInsets.top
        self.hasNotch = safeTop > 0

        if let left = screen.auxiliaryTopLeftArea?.width,
           let right = screen.auxiliaryTopRightArea?.width {
            // +4 : les coins bas du cran sont arrondis, la marge évite que
            // le noir laisse deux triangles de papier peint.
            self.notchWidth = max(120, screenFrame.width - left - right + 4)
        } else {
            self.notchWidth = 200
        }

        if hasNotch {
            self.notchHeight = safeTop + 1
        } else {
            // Sans cran : hauteur de la barre de menus, pour rester cohérent
            // si l'on décide un jour d'afficher l'îlot sur un écran externe.
            self.notchHeight = max(24, screenFrame.maxY - screen.visibleFrame.maxY)
        }
    }

    /// Cadre au repos : uniquement la hauteur de la barre de menus, avec une
    /// petite marge de chaque côté du cran. Aucun fond n'y est peint : seul
    /// l'œil du thème flotte à gauche de la caméra.
    var closedFrame: NSRect {
        let width = notchWidth + Self.wingWidth * 2
        return NSRect(x: screenFrame.midX - width / 2,
                      y: screenFrame.maxY - notchHeight,
                      width: width,
                      height: notchHeight)
    }

    /// Cadre déplié : ancré au bord haut de l'écran, centré, et qui descend
    /// sous le cran de `contentHeight` points.
    func openFrame(width: CGFloat, contentHeight: CGFloat) -> NSRect {
        let frameWidth = max(notchWidth, width)
        return NSRect(x: screenFrame.midX - frameWidth / 2,
                      y: screenFrame.maxY - notchHeight - contentHeight,
                      width: frameWidth,
                      height: notchHeight + contentHeight)
    }

    /// Le cran est-il toujours là, et à la même place ? Sert à ne pas
    /// repositionner la fenêtre à chaque relevé.
    func isSameLayout(as other: NotchGeometry?) -> Bool {
        guard let other else { return false }
        return other.screen === screen
            && other.closedFrame.equalTo(closedFrame)
            && other.hasNotch == hasNotch
    }
}
