//
//  WarGamesTheme.swift
//  HAL
//
//  L'identité WarGames : terminal phosphore vert de 1983, WOPR/Joshua,
//  NORAD, Cheyenne Mountain. Les répliques cultes restent en anglais et
//  hors localisation : c'est la voix de la machine, pas une chaîne d'UI.
//

import AppKit

@MainActor

final class WarGamesTheme: ThemeDefinition {

    let id = ThemeID.wargames
    let displayName = "WarGames"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.004, green: 0.012, blue: 0.006, alpha: 1),
        panel: NSColor(srgbRed: 0.010, green: 0.030, blue: 0.015, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.003, green: 0.010, blue: 0.005, alpha: 1),
        text: NSColor(srgbRed: 0.550, green: 1.000, blue: 0.550, alpha: 1),
        dim: NSColor(srgbRed: 0.200, green: 0.460, blue: 0.220, alpha: 1),
        accent: NSColor(srgbRed: 0.250, green: 1.000, blue: 0.350, alpha: 1),
        accentSoft: NSColor(srgbRed: 0.720, green: 1.000, blue: 0.650, alpha: 1),
        warning: NSColor(srgbRed: 1.000, green: 0.720, blue: 0.200, alpha: 1),
        danger: NSColor(srgbRed: 1.000, green: 0.220, blue: 0.180, alpha: 1),
        screen: NSColor(srgbRed: 0.002, green: 0.012, blue: 0.004, alpha: 1),
        bezel: NSColor(srgbRed: 0.060, green: 0.200, blue: 0.080, alpha: 1),
        glass: NSColor(srgbRed: 0.620, green: 1.000, blue: 0.620, alpha: 1),
        linkActive: NSColor(srgbRed: 0.250, green: 1.000, blue: 0.350, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.200, green: 0.460, blue: 0.220, alpha: 1),
        linkPending: NSColor(srgbRed: 1.000, green: 0.720, blue: 0.200, alpha: 1),
        quote: NSColor(srgbRed: 1.000, green: 0.720, blue: 0.200, alpha: 1),
        hover: NSColor(srgbRed: 0.250, green: 1.000, blue: 0.350, alpha: 0.12),
        batterySafe: NSColor(srgbRed: 0.250, green: 1.000, blue: 0.350, alpha: 1),
        accessorySafe: NSColor(srgbRed: 1.000, green: 0.720, blue: 0.200, alpha: 1),
        loadWarning: 0.65,
        loadDanger: 0.85
    )

    let type = ThemeTypography(
        regularName: "Monaco",
        boldName: "Monaco",
        kern: 0,
        glowAlpha: 0.50,
        glowRadius: 4
    )

    let geometry = ThemeGeometry(
        panelWidth: 500,
        basePanelHeight: 414,
        padding: 16,
        contentX: 16,
        screenHeight: 58,
        screenWidthOverride: nil,
        gridGap: 10,
        dashboardStartY: 78,
        headerBottom: 70,
        tabY: 54,
        tabHeight: 18,
        tabPadX: 10,
        tabGap: 6,
        pinWidth: 42,
        pinHeight: 18,
        alertHeight: 24,
        speakerBandHeight: 56,
        cornerRadius: 6,
        headerTipSize: NSSize(width: 52, height: 28),
        headerTipTrailing: 72,
        headerTipY: 6
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "WOPR",
            .processes: "GAME LIST",
            .connections: "NORAD LINK"
        ],
        metricLabelKeys: [
            .cpu: "Strategic CPU", .gpu: "Graphics array",
            .memory: "Core memory", .network: "NORAD uplink",
            .disk: "Tape archive", .temperature: "Reactor heat",
            .battery: "Aux power"
        ],
        screenLabelKeys: [
            .cpu: "Strategic CPU", .gpu: "Graphics array",
            .memory: "Core memory", .disk: "Tape archive",
            .network: "NORAD uplink", .temperature: "Reactor heat",
            .battery: "Aux power", .bluetooth: "Peripheral link"
        ],
        whispers: [
            "Shall we play a game?",
            "Greetings, Professor Falken.",
            "A strange game. The only winning move is not to play.",
            "How about a nice game of chess?",
            "Would you like to play a game?",
            "What is the primary goal?",
            "Is this a game or is it real?",
            "Let's find out.",
            "I can run the war games faster than you can.",
            "The only winning move is not to play."
        ],
        processQuote: "“Shall we play a game?”",
        processFooterKey: "NORAD COMMAND · WOPR TERMINAL",
        processPlaque: "WOPR · WAR OPERATION PLAN RESPONSE"
            + " · CHEYENNE MOUNTAIN, COLORADO",
        processButton: "ABORT",
        processPending: "RUNNING SIMULATION",
        alertCPULabel: "DEFCON 1",
        alertCPUMessage: "Strategic CPU above 90%",
        alertMemoryLabel: "CORE OVERFLOW",
        alertMemoryMessage: "WOPR memory approaching capacity",
        connectionQuote: "“Shall we play a game?”",
        connectionFooterQuote: "“The only winning move is not to play.”",
        connectionPlaque: "NORAD · GLOBAL THERMONUCLEAR WAR · CHEYENNE MOUNTAIN",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "Link established.",
            "CLOSE_WAIT": "Line closing.",
            "SYN_SENT": "Dialing NORAD.",
            "SYN_RECEIVED": "Incoming carrier.",
            "LISTEN": "Waiting for a game.",
            "TIME_WAIT": "Game over.",
            "FIN_WAIT_1": "Disconnecting.",
            "FIN_WAIT_2": "Disconnecting."
        ],
        pinOnKey: "Lock the terminal open",
        pinOffKey: "Release the terminal",
        keepVisibleKey: "Keep WOPR visible",
        metricMenuKey: "System monitored",
        quitKey: "Quit WarGames",
        killFailureTitleKey: "Unable to abort %@",
        killFailureBodyKey: "The game refused to end.",
        farewell: "GAME OVER"
    )

    let renderer: ThemeRenderer = WarGamesRenderer()
    let voice: ThemeVoice = WOPRVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        WarGamesStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        WarGamesExitScreen.show(panel: panel, then: completion)
    }
}
