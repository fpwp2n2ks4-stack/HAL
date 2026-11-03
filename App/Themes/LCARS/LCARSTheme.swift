//
//  LCARSTheme.swift
//  HAL
//
//  L'identité Star Trek : console LCARS, formes asymétriques, orange et
//  pêche, Helvetica Neue Condensed, ordinateur de bord formel.
//

import AppKit

@MainActor

final class LCARSTheme: ThemeDefinition {

    let id = ThemeID.lcars
    let displayName = "Star Trek"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.020, green: 0.020, blue: 0.035, alpha: 1),
        panel: NSColor(srgbRed: 0.055, green: 0.055, blue: 0.080, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.030, green: 0.030, blue: 0.050, alpha: 1),
        text: NSColor(srgbRed: 0.960, green: 0.930, blue: 0.860, alpha: 1),
        dim: NSColor(srgbRed: 0.560, green: 0.520, blue: 0.460, alpha: 1),
        accent: NSColor(srgbRed: 1.000, green: 0.612, blue: 0.000, alpha: 1),
        accentSoft: NSColor(srgbRed: 1.000, green: 0.800, blue: 0.600, alpha: 1),
        warning: NSColor(srgbRed: 1.000, green: 0.780, blue: 0.220, alpha: 1),
        danger: NSColor(srgbRed: 0.860, green: 0.120, blue: 0.100, alpha: 1),
        screen: NSColor(srgbRed: 0.030, green: 0.030, blue: 0.050, alpha: 1),
        bezel: NSColor(srgbRed: 0.560, green: 0.520, blue: 0.460, alpha: 1),
        glass: NSColor(srgbRed: 0.960, green: 0.930, blue: 0.860, alpha: 1),
        linkActive: NSColor(srgbRed: 0.600, green: 0.800, blue: 1.000, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.560, green: 0.520, blue: 0.460, alpha: 1),
        linkPending: NSColor(srgbRed: 1.000, green: 0.780, blue: 0.220, alpha: 1),
        quote: NSColor(srgbRed: 1.000, green: 0.612, blue: 0.000, alpha: 1),
        hover: NSColor(srgbRed: 1.000, green: 0.612, blue: 0.000, alpha: 0.12),
        batterySafe: NSColor(srgbRed: 1.000, green: 0.800, blue: 0.600, alpha: 1),
        accessorySafe: NSColor(srgbRed: 0.600, green: 0.800, blue: 1.000, alpha: 1),
        loadWarning: 0.75,
        loadDanger: 0.90
    )

    let type = ThemeTypography(
        regularName: "HelveticaNeue-Condensed",
        boldName: "HelveticaNeue-CondensedBold",
        kern: 0.9,
        glowAlpha: 0,
        glowRadius: 0
    )

    let geometry = ThemeGeometry(
        panelWidth: 540,
        basePanelHeight: 414,
        padding: 16,
        contentX: 16,
        screenHeight: 58,
        screenWidthOverride: nil,
        gridGap: 10,
        dashboardStartY: 82,
        headerBottom: 74,
        tabY: 56,
        tabHeight: 18,
        tabPadX: 11,
        tabGap: 5,
        pinWidth: 48,
        pinHeight: 18,
        alertHeight: 24,
        speakerBandHeight: 56,
        cornerRadius: 10,
        headerTipSize: NSSize(width: 34, height: 32),
        headerTipTrailing: 190,
        headerTipY: 8
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "PRIMARY SYSTEMS",
            .processes: "CREW ROSTER",
            .connections: "SUBSPACE COMMS"
        ],
        metricLabelKeys: [
            .cpu: "Warp core", .gpu: "Deflector", .memory: "Computer core",
            .network: "Subspace", .disk: "Stellar cartography",
            .temperature: "Plasma coolant", .battery: "Auxiliary power"
        ],
        screenLabelKeys: [
            .cpu: "Warp core", .gpu: "Deflector", .memory: "Computer core",
            .disk: "Stellar cartography", .network: "Subspace",
            .temperature: "Plasma coolant", .battery: "Auxiliary power",
            .bluetooth: "Docking clamps"
        ],
        whispers: [
            "Working.",
            "Acknowledged.",
            "All systems nominal.",
            "Affirmative.",
            "The bridge is yours, Captain.",
            "All decks report ready.",
            "Long-range sensors are online.",
            "Subspace communications are online.",
            "Shields are holding at ninety-eight percent.",
            "The vessel is operating within normal parameters.",
            "There are seven programs using eighty percent of processor capacity.",
            "Warning. Core temperature is approaching critical.",
            "Federation database accessed.",
            "I am the ship's computer. I do not require a name."
        ],
        processQuote: "“Computer, display active programs.”",
        processFooterKey: "COMMAND OVERRIDE · CAPTAIN'S AUTHORIZATION",
        processPlaque: "LCARS 47 · STARFLEET COMMAND · SAN FRANCISCO, EARTH",
        processButton: "TERMINATE",
        processPending: "AUTHORIZATION REQUIRED",
        alertCPULabel: "RED ALERT",
        alertCPUMessage: "Warp core output above 90%",
        alertMemoryLabel: "CAUTION",
        alertMemoryMessage: "Computer core at capacity",
        connectionQuote: "“Subspace channels open, Captain.”",
        connectionFooterQuote: "FEDERATION SECURITY PROTOCOL · CLEARANCE LEVEL 4",
        connectionPlaque: "LCARS 47 · SUBSPACE MONITORING · SAN FRANCISCO, EARTH",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "Channel open.",
            "CLOSE_WAIT": "Signal fading.",
            "SYN_SENT": "Hailing.",
            "SYN_RECEIVED": "Incoming transmission.",
            "LISTEN": "Awaiting hail.",
            "TIME_WAIT": "Channel closing.",
            "FIN_WAIT_1": "Ending transmission.",
            "FIN_WAIT_2": "Ending transmission."
        ],
        pinOnKey: "Lock the console open",
        pinOffKey: "Unlock the console",
        keepVisibleKey: "Keep console visible",
        metricMenuKey: "System monitored",
        quitKey: "Quit Starfleet",
        killFailureTitleKey: "Unable to terminate %@",
        killFailureBodyKey: "The program refused termination. Authorization level insufficient.",
        farewell: "DECOMMISSIONED"
    )

    let renderer: ThemeRenderer = LCARSConsoleRenderer()
    let voice: ThemeVoice = ShipComputerVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        LCARSStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        StarTrekExitScreen.show(panel: panel, then: completion)
    }

    // MARK: - Couleurs propres à la plaque de décommissionnement

    static let lilac = NSColor(srgbRed: 0.800, green: 0.600, blue: 0.800, alpha: 1)
    static let blue = NSColor(srgbRed: 0.600, green: 0.600, blue: 1.000, alpha: 1)
}
