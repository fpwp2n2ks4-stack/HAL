//
//  Theme.swift
//  HAL
//
//  Le contrat de thème : ce qu'une identité doit fournir au noyau.
//
//  Le noyau ne connaît ni les couleurs, ni les textes, ni les polices : il
//  demande au thème sa palette, sa géométrie, son renderer et sa voix. Un
//  thème ne connaît pas la collecte : il reçoit des `Snapshot` déjà prêts.
//

import AppKit

// MARK: - Identité

/// Les identités prévues. Seules celles de `ThemeManager.implemented` sont
/// proposées dans le menu ; les autres sont des emplacements réservés.
enum ThemeID: String, CaseIterable, Codable {
    case hal9000
    case lcars
    case bladeRunner
    case wargames
    case moon
    case matrix
    case ark
    case toasty

    var displayName: String {
        switch self {
        case .hal9000: return "HAL 9000"
        case .lcars: return "Star Trek"
        case .bladeRunner: return "Blade Runner"
        case .wargames: return "WarGames"
        case .moon: return "Moon"
        case .matrix: return "Matrix"
        case .ark: return "The Ark"
        case .toasty: return "Toasty"
        }
    }

    /// Thèmes plats et sobres : texte plein plutôt que verre dépoli, pas de
    /// halo, noms en gras. Le noyau s'y réfère pour ses exceptions de
    /// lisibilité — un thème sobre ne doit pas hériter des effets des
    /// vaisseaux lumineux.
    var isFlat: Bool {
        self == .moon || self == .toasty
    }
}

/// Les huit écrans du tableau de bord, indépendamment du vocabulaire du
/// thème : HAL parle de CPU, LCARS de moteur de distorsion.
enum ScreenSlot: String, CaseIterable {
    case cpu
    case gpu
    case memory
    case disk
    case network
    case temperature
    case battery
    case bluetooth
}

/// Les deux ressources qui peuvent hurler en même temps.
enum AlertKind {
    case cpu
    case memory
}

// MARK: - Palette

/// Les couleurs d'un thème, nommées par leur **rôle**, jamais par leur
/// teinte : `accent` est le vert phosphore de HAL et l'orange de LCARS.
struct ThemePalette {
    let background: NSColor
    let panel: NSColor
    let panelDeep: NSColor
    let text: NSColor
    let dim: NSColor
    let accent: NSColor
    let accentSoft: NSColor
    let warning: NSColor
    let danger: NSColor
    let screen: NSColor
    let bezel: NSColor
    let glass: NSColor
    let linkActive: NSColor
    let linkIdle: NSColor
    let linkPending: NSColor
    let quote: NSColor
    let hover: NSColor
    let batterySafe: NSColor
    let accessorySafe: NSColor
    let loadWarning: Double
    let loadDanger: Double

    /// Couleur d'une valeur selon la charge qu'elle mesure.
    func load(_ fraction: Double) -> NSColor {
        switch fraction {
        case ..<loadWarning: return accent
        case ..<loadDanger: return warning
        default: return danger
        }
    }

    // MARK: Batterie — la norme d'Apple

    /// Seuil de batterie basse, en pourcents : 20 %, la valeur à laquelle
    /// macOS et iOS passent l'icône au rouge.
    static let batteryLowLevel = 20

    static func isBatteryLow(_ level: Int) -> Bool { level <= batteryLowLevel }

    /// La batterie s'affiche en rouge : basse, **sauf** si le jaune
    /// d'Apple s'impose déjà — Mode économie d'énergie ou plafond de
    /// charge atteint. Chez Apple le jaune passe avant le rouge.
    static func isBatteryCritical(_ battery: BatteryStatus) -> Bool {
        !(battery.isLowPowerMode || battery.isAtChargeLimit)
            && isBatteryLow(battery.level)
    }

    /// Couleur d'une batterie, selon la norme d'Apple : ambre si le Mode
    /// économie d'énergie est actif ou si la charge est retenue au plafond,
    /// rouge à 20 % et en dessous, couleur nominale du thème ailleurs.
    /// Aucun seuil haut : un plein n'est pas une alarme.
    func battery(_ battery: BatteryStatus) -> NSColor {
        if battery.isLowPowerMode || battery.isAtChargeLimit { return warning }
        return Self.isBatteryLow(battery.level) ? danger : batterySafe
    }

    /// Un accessoire Bluetooth ne garde que le seuil bas : c'est une
    /// réserve, pas une saturation, et le Mode économie d'énergie ne le
    /// concerne pas.
    func accessory(_ level: Int) -> NSColor {
        Self.isBatteryLow(level) ? danger : accessorySafe
    }
}

// MARK: - Typographie

/// La police et le halo d'un thème. Le poids est explicite partout : HAL
/// n'est pas gras par défaut, LCARS si.
struct ThemeTypography {
    let regularName: String
    let boldName: String
    let kern: CGFloat
    let glowAlpha: CGFloat
    let glowRadius: CGFloat

    func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
        NSFont(name: bold ? boldName : regularName, size: size)
            ?? .systemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    /// Halo lumineux, quand le thème en veut un (tube cathodique). Renvoie
    /// `nil` pour les thèmes plats, qui ne doivent pas porter d'ombre.
    func glow(_ color: NSColor, radius: CGFloat? = nil) -> NSShadow? {
        guard glowAlpha > 0 else { return nil }
        let shadow = NSShadow()
        shadow.shadowColor = color.withAlphaComponent(glowAlpha)
        shadow.shadowBlurRadius = radius ?? glowRadius
        shadow.shadowOffset = .zero
        return shadow
    }

    /// Attributs de dessin complets. `glow` est opt-in : un libellé se lit,
    /// il ne brille pas ; une valeur, si.
    func attributes(_ size: CGFloat, color: NSColor, bold: Bool = false,
                    kern: CGFloat? = nil, glow: Bool = false)
        -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font(size, bold: bold),
            .foregroundColor: color
        ]
        let spacing = kern ?? self.kern
        if spacing != 0 { attrs[.kern] = spacing }
        if glow, let shadow = self.glow(color) { attrs[.shadow] = shadow }
        return attrs
    }
}

// MARK: - Géométrie

/// Les dimensions qui changent d'un thème à l'autre. La largeur du panneau
/// et la hauteur de base sont ici, pas dans le noyau.
struct ThemeGeometry {
    let panelWidth: CGFloat
    let basePanelHeight: CGFloat
    let padding: CGFloat
    let contentX: CGFloat
    let screenHeight: CGFloat
    /// `nil` : largeur calculée pour remplir la ligne (LCARS). Une valeur
    /// fixe garde la grille d'origine (HAL).
    let screenWidthOverride: CGFloat?
    let gridGap: CGFloat
    let dashboardStartY: CGFloat
    let headerBottom: CGFloat
    let tabY: CGFloat
    let tabHeight: CGFloat
    let tabPadX: CGFloat
    let tabGap: CGFloat
    let pinWidth: CGFloat
    let pinHeight: CGFloat
    let alertHeight: CGFloat
    let speakerBandHeight: CGFloat
    let cornerRadius: CGFloat
    let headerTipSize: NSSize
    let headerTipTrailing: CGFloat
    let headerTipY: CGFloat

    func screenWidth(in panelWidth: CGFloat) -> CGFloat {
        screenWidthOverride
            ?? (panelWidth - contentX - padding - gridGap) / 2
    }

    /// Zone invisible posée sur l'œil (HAL) ou l'insigne (LCARS) de
    /// l'en-tête : elle ne sert qu'à porter l'infobulle et à déclencher la
    /// voix.
    func headerTipRect(in panelWidth: CGFloat) -> NSRect {
        NSRect(x: panelWidth - headerTipTrailing, y: headerTipY,
               width: headerTipSize.width, height: headerTipSize.height)
    }
}

// MARK: - Textes

/// Tout ce qui se dit, se lance ou se plaint dans un thème.
///
/// Les répliques cultes restent des **clés anglaises** : `randomWhisper()`
/// les passe à `loc()`, si bien que l'infobulle et la voix suivent la langue
/// de l'application. Le texte affiché à la fermeture reste, lui, dans la
/// langue d'origine du thème ; seule sa prononciation est traduite.
struct ThemeCopy {
    let tabTitles: [PanelView.Tab: String]
    let metricLabelKeys: [SystemMetric: String]
    let screenLabelKeys: [ScreenSlot: String]

    /// Répliques cultes, en anglais : clés de traduction pour l'infobulle
    /// comme pour la voix.
    let whispers: [String]

    let processQuote: String
    let processFooterKey: String?
    let processPlaque: String
    let processButton: String
    let processPending: String

    let alertCPULabel: String
    let alertCPUMessage: String
    let alertMemoryLabel: String
    let alertMemoryMessage: String

    let connectionQuote: String
    let connectionFooterQuote: String
    let connectionPlaque: String
    let connectionNoteKey: String?
    let connectionGlosses: [String: String]

    let pinOnKey: String
    let pinOffKey: String
    let keepVisibleKey: String
    let metricMenuKey: String
    let quitKey: String

    let killFailureTitleKey: String
    let killFailureBodyKey: String

    /// « GOOD BYE », « DECOMMISSIONED »… : le dernier mot du thème, affiché
    /// tel quel à la fermeture.
    let farewell: String

    /// La même phrase, mais prononcée dans la langue de l'application.
    var spokenFarewell: String { loc(farewell) }

    func metricLabel(_ metric: SystemMetric) -> String {
        loc(metricLabelKeys[metric] ?? "CPU")
    }

    func screenLabel(_ slot: ScreenSlot) -> String {
        loc(screenLabelKeys[slot] ?? "")
    }

    /// Une réplique tirée au hasard, déjà traduite : l'infobulle et la voix
    /// disent la même chose, dans la même langue.
    func randomWhisper() -> String {
        loc(whispers.randomElement() ?? "")
    }

    /// Glose d'un état TCP : le commentaire du thème sur la donnée brute.
    func gloss(for state: String) -> String? {
        connectionGlosses[state]
    }
}

// MARK: - Rendu

/// Le dessin propre au thème. Le noyau décide **quoi** dessiner et où ;
/// le renderer décide **comment**.
@MainActor
protocol ThemeRenderer {
    func drawBackground(in view: PanelView)
    func drawHeader(in view: PanelView)
    func drawTabs(in view: PanelView, tabRects: [PanelView.Tab: NSRect],
                  pinRect: NSRect)

    func drawScreen(in view: PanelView, spec: ScreenSpec)

    func drawAlert(in view: PanelView, spec: AlertSpec)

    func drawScanlines(in view: PanelView)

    /// La bande sonore du tableau de bord, chrome et contenu : sa
    /// composition fait partie de l'identité.
    func drawAudioBand(in view: PanelView, rect: NSRect)

    /// Une ligne de processus : surbrillance, bouton, ou demande
    /// d'autorisation en cours.
    func drawProcessAction(in view: PanelView, spec: ProcessActionSpec)
}

// MARK: - Voix

/// La synthèse vocale du thème. Un seul exemplaire par thème : deux
/// phrases simultanées produiraient un brouhaha indigne d'un ordinateur
/// de bord.
@MainActor
protocol ThemeVoice: AnyObject {
    var voiceName: String { get }
    func say(_ text: String)
    func hush()
}

// MARK: - Définition

/// Ce qu'un thème est, et ce qu'il sait fabriquer. Le `ThemeManager`
/// assemble ; l'`AppDelegate` consomme.
@MainActor
protocol ThemeDefinition: AnyObject {
    var id: ThemeID { get }
    var displayName: String { get }
    var palette: ThemePalette { get }
    var type: ThemeTypography { get }
    var geometry: ThemeGeometry { get }
    var copy: ThemeCopy { get }
    var renderer: ThemeRenderer { get }
    var voice: ThemeVoice { get }

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView
    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void)
}
