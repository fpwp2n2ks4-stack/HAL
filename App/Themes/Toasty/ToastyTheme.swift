//
//  ToastyTheme.swift
//  HAL
//
//  L'identité Toasty : le grille-pain de la flotte coloniale. Dans
//  Battlestar Galactica, « toaster » est le surnom que les humains donnent
//  aux Cylons — un moniteur qui s'appelle Toasty et porte un œil rouge
//  balayant est donc exactement ce qu'il prétend être. Console d'atelier
//  sobre, jauges à segments héritées de Toasty, et la politesse tranquille
//  d'une machine qui a un plan.
//

import AppKit

@MainActor

final class ToastyTheme: ThemeDefinition {

    let id = ThemeID.toasty
    let displayName = "Toasty"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.145, green: 0.137, blue: 0.129, alpha: 1),
        panel: NSColor(srgbRed: 0.176, green: 0.167, blue: 0.157, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.129, green: 0.122, blue: 0.114, alpha: 1),
        text: NSColor(srgbRed: 0.906, green: 0.886, blue: 0.851, alpha: 1),
        dim: NSColor(srgbRed: 0.541, green: 0.502, blue: 0.459, alpha: 1),
        accent: NSColor(srgbRed: 0.839, green: 0.161, blue: 0.090, alpha: 1),
        accentSoft: NSColor(srgbRed: 0.749, green: 0.220, blue: 0.130, alpha: 1),
        warning: NSColor(srgbRed: 0.851, green: 0.573, blue: 0.161, alpha: 1),
        danger: NSColor(srgbRed: 0.949, green: 0.220, blue: 0.129, alpha: 1),
        screen: NSColor(srgbRed: 0.145, green: 0.137, blue: 0.129, alpha: 1),
        bezel: NSColor(srgbRed: 0.353, green: 0.329, blue: 0.298, alpha: 1),
        glass: NSColor(srgbRed: 0.847, green: 0.827, blue: 0.796, alpha: 1),
        linkActive: NSColor(srgbRed: 0.878, green: 0.310, blue: 0.173, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.400, green: 0.459, blue: 0.529, alpha: 1),
        linkPending: NSColor(srgbRed: 0.851, green: 0.573, blue: 0.161, alpha: 1),
        quote: NSColor(srgbRed: 0.878, green: 0.859, blue: 0.827, alpha: 1),
        hover: NSColor(srgbRed: 1.000, green: 1.000, blue: 1.000, alpha: 0.08),
        batterySafe: NSColor(srgbRed: 0.416, green: 0.678, blue: 0.365, alpha: 1),
        accessorySafe: NSColor(srgbRed: 0.416, green: 0.678, blue: 0.365, alpha: 1),
        loadWarning: 0.72,
        loadDanger: 0.90
    )

    let type = ThemeTypography(
        regularName: "Helvetica",
        boldName: "Helvetica-Bold",
        kern: 0.3,
        glowAlpha: 0,
        glowRadius: 0
    )

    let geometry = ThemeGeometry(
        panelWidth: 470,
        // 24 px de plus que HAL : l'en-tête Toasty est plus haut (il porte
        // l'œil), la bande son aurait sinon été rognée à 34 px par la marge
        // basse — et la pochette avec. Ici, la bande garde ses 56 px et la
        // pochette égale celle de HAL.
        basePanelHeight: 438,
        padding: 16,
        contentX: 16,
        screenHeight: 58,
        screenWidthOverride: 213,
        gridGap: 10,
        dashboardStartY: 98,
        headerBottom: 94,
        tabY: 74,
        tabHeight: 16,
        tabPadX: 8,
        tabGap: 6,
        pinWidth: 16,
        pinHeight: 16,
        alertHeight: 22,
        speakerBandHeight: 56,
        cornerRadius: 6,
        headerTipSize: NSSize(width: 58, height: 24),
        headerTipTrailing: 74,
        headerTipY: 34
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "SYSTEMS",
            .processes: "MANIFEST",
            .connections: "WIRELESS"
        ],
        metricLabelKeys: [
            .cpu: "Mainframe", .gpu: "Fire control", .memory: "Core",
            .network: "Wireless", .disk: "FTL drive", .temperature: "Coolant",
            .battery: "Tylium"
        ],
        screenLabelKeys: [
            .cpu: "MAINFRAME", .gpu: "FIRE CONTROL", .memory: "CORE",
            .disk: "FTL DRIVE", .network: "WIRELESS", .temperature: "COOLANT",
            .battery: "TYLIUM", .bluetooth: "RAPTORS"
        ],
        // Le générique de Battlestar Galactica, presque mot pour mot, plus
        // l'ordre d'un Cylon de 1978 et le cri de la flotte.
        whispers: [
            "By your command.",
            "The Cylons were created by man.",
            "They evolved.",
            "They rebelled.",
            "There are many copies.",
            "And they have a plan.",
            "All of this has happened before.",
            "But it has not all happened to you.",
            "So say we all.",
            "Frak off."
        ],
        processQuote: "“Shall we airlock this process, sir?”",
        processFooterKey: "COLONIAL FLEET",
        processPlaque: "BS-75 GALACTICA · CIC",
        processButton: "AIRLOCK",
        processPending: "BY YOUR COMMAND",
        alertCPULabel: "",
        alertCPUMessage: "ACTION STATIONS",
        alertMemoryLabel: "",
        alertMemoryMessage: "ACTION STATIONS",
        connectionQuote: "“DRADIS is watching the fleet, sir.”",
        connectionFooterQuote: "COLONIAL FLEET",
        connectionPlaque: "BS-75 GALACTICA · DRADIS",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "CONTACT",
            "SYN_SENT": "SCANNING",
            "SYN_RECEIVED": "INBOUND",
            "LISTEN": "ON STATION",
            "CLOSE_WAIT": "LOST",
            "TIME_WAIT": "LOST",
            "FIN_WAIT_1": "LOST",
            "FIN_WAIT_2": "LOST"
        ],
        pinOnKey: "Keep the CIC open",
        pinOffKey: "Allow to close",
        keepVisibleKey: "Keep the CIC visible",
        metricMenuKey: "Metric shown",
        quitKey: "Quit Galactica",
        killFailureTitleKey: "Unable to airlock %@",
        killFailureBodyKey: "Not without the Admiral's approval, sir.",
        farewell: "SO SAY WE ALL."
    )

    let renderer: ThemeRenderer = ToastyRenderer()
    let voice: ThemeVoice = ToastyVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        ToastyStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        ToastyExitScreen.show(panel: panel, then: completion)
    }
}
