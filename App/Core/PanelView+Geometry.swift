//
//  PanelView+Geometry.swift
//  HAL
//
//  Géométrie pilotée par le thème. Le noyau ne fige plus ni la largeur, ni
//  la position des données : il interroge `theme.geometry`.
//

import AppKit

/// Zone invisible posée sur un élément du panneau, qui ne sert qu'à porter
/// une infobulle.
///
/// Une sous-vue ordinaire qui ne dessine rien ne répond pas au test de
/// survol : `hitTest` renvoie `nil`, AppKit n'a donc personne à qui poser
/// la question du `toolTip`, et rien ne s'affiche jamais. Cette vue se
/// déclare explicitement survolable ; comme elle ne dessine rien et ne
/// traite aucune souris, elle reste invisible et inerte.
final class HoverTipView: NSView {

    override var isFlipped: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? { self }

    override func draw(_ dirtyRect: NSRect) {
        // Volontairement vide : cette vue n'est qu'un porteur d'infobulle.
    }
}

extension PanelView {

    // MARK: - Géométrie du thème

    var panelWidth: CGFloat { theme.geometry.panelWidth }
    var basePanelHeight: CGFloat { theme.geometry.basePanelHeight }

    /// Hauteur du panneau : la base, plus une bande d'alarme par ressource
    /// saturée — CPU et mémoire peuvent hurler en même temps.
    var panelHeight: CGFloat {
        basePanelHeight + CGFloat(alertCount) * 30
    }

    /// Nombre de bandes d'alarme affichées au-dessus du dashboard.
    var alertCount: Int {
        (cpuIsCritical ? 1 : 0) + (memoryIsCritical ? 1 : 0)
    }

    // MARK: - Zones partagées avec les extensions de dessin

    var padding: CGFloat { theme.geometry.padding }
    var contentX: CGFloat { theme.geometry.contentX }
    var contentW: CGFloat { bounds.width - contentX - padding }
    var screenW: CGFloat { theme.geometry.screenWidth(in: bounds.width) }
    var screenH: CGFloat { theme.geometry.screenHeight }
    var gridGap: CGFloat { theme.geometry.gridGap }

    static let processRowCount = 10
    static let processRowHeight: CGFloat = 22

    /// Lignes affichées par zone de l'onglet connexions. Chaque ligne porte
    /// l'adresse locale en second plan, d'où une hauteur double.
    static let connectionRowCount = 4
    static let connectionRowHeight: CGFloat = 22
}
