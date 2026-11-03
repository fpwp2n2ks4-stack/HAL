//
//  ThemeSpecs.swift
//  HAL
//
//  Les specifications de dessin que le noyau passe aux renderers : tout
//  ce qu'il faut pour un ecran, une alerte ou une action de processus.
//  Un renderer ne recoit jamais dix parametres orphelins : il recoit une
//  intention, dans un struct nomme.
//

import AppKit

// MARK: - Ligne de texte

/// Une ligne de texte prête à dessiner : le trio que toutes les bandes
/// audio de thèmes formaient en tuple.
struct TextLine {
    let text: String
    let font: NSFont
    let color: NSColor
}

// MARK: - Écran du tableau de bord

/// Ce que le noyau demande à dessiner d'un écran du tableau de bord : la
/// zone, les textes, la charge. Le renderer décide du reste.
struct ScreenSpec {
    let rect: NSRect
    let label: String
    let value: String
    let sub: String
    let hot: Bool
    let small: Bool
    let fraction: Double
    let tint: NSColor?
}

// MARK: - Alerte

/// Une bande d'alerte : laquelle, où, avec quel texte, et si elle hurle.
struct AlertSpec {
    let rect: NSRect
    let kind: AlertKind
    let label: String
    let message: String
    let visible: Bool
}

// MARK: - Action de processus

/// L'action d'une ligne de processus : surbrillance, bouton, ou demande
/// d'autorisation en cours.
struct ProcessActionSpec {
    let rowRect: NSRect
    let buttonRect: NSRect
    let title: String
    let enabled: Bool
    let hovered: Bool
    let pending: (text: String, since: Date)?
}
