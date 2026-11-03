//
//  StatusItemView.swift
//  HAL
//
//  La base des vues de barre de menus : le thème fournit le dessin, le
//  noyau fournit le relevé et la métrique choisie. Un fichier propre
//  pour une classe que chaque vaisseau dérange.
//

import AppKit

// MARK: - Vue d'état commune

/// Base des vues de barre de menus. Une seule mécanique : le thème fournit
/// le dessin, le noyau fournit le relevé et la métrique choisie.
class StatusItemView: NSView {

    let theme: ThemeDefinition

    var snapshot: Snapshot {
        didSet {
            snapshotDidChange()
            needsDisplay = true
        }
    }

    init(theme: ThemeDefinition, snapshot: Snapshot) {
        self.theme = theme
        self.snapshot = snapshot
        super.init(frame: NSRect(x: 0, y: 0, width: 96, height: 18))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }

    /// La métrique choisie dans le menu, commune à tous les thèmes.
    var metric: SystemMetric { SystemMetric.current }
    var fraction: Double { metric.fraction(snapshot) }

    /// Faux quand seul l'insigne doit apparaître — l'îlot au repos, par
    /// exemple. Les renderers dessinent `readout` : une valeur vide s'efface
    /// d'elle-même, sans qu'aucun thème ait à connaître ce mode.
    var showsReadout = true {
        didSet { needsDisplay = true }
    }

    var readout: String { showsReadout ? metric.readout(snapshot) : "" }
    var isCritical: Bool { metric.isCritical(snapshot) }

    /// Crochet de vie : un clignement, un battement, une phase. Ne redessine
    /// pas lui-même, le `didSet` s'en charge.
    func snapshotDidChange() {}

    /// Taille de la valeur à côté de la marque, commune aux thèmes : petite,
    /// monospacée, pour que les chiffres ne dansent pas d'un relevé à
    /// l'autre. Le thème ne change que la marque, pas la donnée.
    var readoutFont: NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold)
    }

    func readoutWidth(_ text: String) -> CGFloat {
        text.size(withAttributes: [.font: readoutFont]).width
    }
}
