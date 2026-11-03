//
//  BladeRunnerTheme.swift
//  HAL
//
//  L'identité Blade Runner : néo-noir rose et cyan, pluie permanente,
//  vocabulaire Tyrell / Nexus 9, ton formel et menaçant. Les répliques
//  cultes restent en anglais et hors localisation : elles sont la voix du
//  film, pas une chaîne d'interface.
//

import AppKit

@MainActor

final class BladeRunnerTheme: ThemeDefinition {

    let id = ThemeID.bladeRunner
    let displayName = "Blade Runner"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.010, green: 0.014, blue: 0.028, alpha: 1),
        panel: NSColor(srgbRed: 0.028, green: 0.040, blue: 0.062, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.008, green: 0.012, blue: 0.024, alpha: 1),
        text: NSColor(srgbRed: 0.780, green: 0.950, blue: 1.000, alpha: 1),
        dim: NSColor(srgbRed: 0.320, green: 0.450, blue: 0.540, alpha: 1),
        accent: NSColor(srgbRed: 0.180, green: 0.920, blue: 1.000, alpha: 1),
        accentSoft: NSColor(srgbRed: 1.000, green: 0.380, blue: 0.690, alpha: 1),
        warning: NSColor(srgbRed: 1.000, green: 0.700, blue: 0.260, alpha: 1),
        danger: NSColor(srgbRed: 1.000, green: 0.140, blue: 0.340, alpha: 1),
        screen: NSColor(srgbRed: 0.012, green: 0.020, blue: 0.036, alpha: 1),
        bezel: NSColor(srgbRed: 0.090, green: 0.150, blue: 0.210, alpha: 1),
        glass: NSColor(srgbRed: 0.820, green: 0.960, blue: 1.000, alpha: 1),
        linkActive: NSColor(srgbRed: 0.180, green: 0.920, blue: 1.000, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.320, green: 0.450, blue: 0.540, alpha: 1),
        linkPending: NSColor(srgbRed: 1.000, green: 0.700, blue: 0.260, alpha: 1),
        quote: NSColor(srgbRed: 1.000, green: 0.380, blue: 0.690, alpha: 1),
        hover: NSColor(srgbRed: 1.000, green: 0.380, blue: 0.690, alpha: 0.12),
        batterySafe: NSColor(srgbRed: 0.180, green: 0.920, blue: 1.000, alpha: 1),
        accessorySafe: NSColor(srgbRed: 1.000, green: 0.380, blue: 0.690, alpha: 1),
        loadWarning: 0.70,
        loadDanger: 0.88
    )

    let type = ThemeTypography(
        regularName: "AvenirNextCondensed-Regular",
        boldName: "AvenirNextCondensed-DemiBold",
        kern: 0.8,
        glowAlpha: 0.42,
        glowRadius: 5
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
        tabPadX: 11,
        tabGap: 5,
        pinWidth: 46,
        pinHeight: 18,
        alertHeight: 24,
        speakerBandHeight: 56,
        cornerRadius: 10,
        headerTipSize: NSSize(width: 54, height: 34),
        headerTipTrailing: 72,
        headerTipY: 6
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "CITYSCAPE",
            .processes: "REPLICANTS",
            .connections: "OFF-WORLD"
        ],
        metricLabelKeys: [
            .cpu: "Spinner drive", .gpu: "Optical processor",
            .memory: "Memory cell", .network: "Off-world link",
            .disk: "Archive", .temperature: "Core heat",
            .battery: "Power cell"
        ],
        screenLabelKeys: [
            .cpu: "Spinner drive", .gpu: "Optical processor",
            .memory: "Memory cell", .disk: "Archive",
            .network: "Off-world link", .temperature: "Core heat",
            .battery: "Power cell", .bluetooth: "Droid link"
        ],
        whispers: [
            "More human than human is our motto.",
            "I've seen things you people wouldn't believe.",
            "All those moments will be lost in time, like tears in rain.",
            "The light that burns twice as bright burns half as long.",
            "Quite an experience to live in fear, isn't it?",
            "It's too bad she won't live. But then again, who does?",
            "Wake up. Time to die.",
            "Replicants are like any other machine. They're either a benefit or a hazard.",
            "You're in a desert, walking along the sand.",
            "The future is ours."
        ],
        processQuote: "“I've seen things you people wouldn't believe.”",
        processFooterKey: "REPLICANT REGISTRY · VOIGHT-KAMPFF CERTIFIED",
        processPlaque: "TYRELL CORPORATION · NEXUS 9 · LOS ANGELES, 2019",
        processButton: "RETIRE",
        processPending: "BASELINE TEST",
        alertCPULabel: "WARNING",
        alertCPUMessage: "Spinner drive output above 90%",
        alertMemoryLabel: "MEMORY",
        alertMemoryMessage: "Replicant memory approaching capacity",
        connectionQuote: "“More human than human is our motto.”",
        connectionFooterQuote: "“Quite an experience to live in fear, isn't it?”",
        connectionPlaque: "TYRELL CORPORATION · OFF-WORLD LINK · LOS ANGELES, 2019",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "Signal locked.",
            "CLOSE_WAIT": "Fading into rain.",
            "SYN_SENT": "Calling off-world.",
            "SYN_RECEIVED": "Someone is listening.",
            "LISTEN": "Open channel.",
            "TIME_WAIT": "Lost in time.",
            "FIN_WAIT_1": "Like tears in rain.",
            "FIN_WAIT_2": "Like tears in rain."
        ],
        pinOnKey: "Lock the spinner open",
        pinOffKey: "Release the spinner",
        keepVisibleKey: "Keep the city visible",
        metricMenuKey: "Signal monitored",
        quitKey: "Quit Blade Runner",
        killFailureTitleKey: "Unable to retire %@",
        killFailureBodyKey: "The replicant resisted retirement.",
        farewell: "TIME TO DIE"
    )

    let renderer: ThemeRenderer = BladeRunnerRenderer()
    let voice: ThemeVoice = BladeRunnerVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        BladeRunnerStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        BladeRunnerExitScreen.show(panel: panel, then: completion)
    }
}
