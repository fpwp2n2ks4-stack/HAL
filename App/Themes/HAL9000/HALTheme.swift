//
//  HALTheme.swift
//  HAL
//
//  L'identité HAL 9000 : vert phosphore, Menlo, œil rouge, ton posé.
//  Tout ce qui faisait HAL dans l'ancien projet est ici — et nulle part
//  ailleurs.
//

import AppKit

@MainActor

final class HALTheme: ThemeDefinition {

    let id = ThemeID.hal9000
    let displayName = "HAL 9000"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.050, green: 0.050, blue: 0.060, alpha: 1),
        panel: NSColor(srgbRed: 0.100, green: 0.130, blue: 0.110, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.030, green: 0.050, blue: 0.040, alpha: 1),
        text: NSColor(srgbRed: 0.300, green: 1.000, blue: 0.480, alpha: 1),
        dim: NSColor(srgbRed: 0.180, green: 0.550, blue: 0.300, alpha: 1),
        accent: NSColor(srgbRed: 0.300, green: 1.000, blue: 0.480, alpha: 1),
        accentSoft: NSColor(srgbRed: 0.820, green: 1.000, blue: 0.900, alpha: 1),
        warning: NSColor(srgbRed: 1.000, green: 0.820, blue: 0.250, alpha: 1),
        danger: NSColor(srgbRed: 1.000, green: 0.300, blue: 0.250, alpha: 1),
        screen: NSColor(srgbRed: 0.030, green: 0.050, blue: 0.040, alpha: 1),
        bezel: NSColor(srgbRed: 0.120, green: 0.160, blue: 0.130, alpha: 1),
        glass: NSColor(srgbRed: 0.820, green: 1.000, blue: 0.900, alpha: 1),
        linkActive: NSColor(srgbRed: 0.300, green: 1.000, blue: 0.480, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.180, green: 0.550, blue: 0.300, alpha: 1),
        linkPending: NSColor(srgbRed: 1.000, green: 0.820, blue: 0.250, alpha: 1),
        quote: NSColor(srgbRed: 1.000, green: 0.820, blue: 0.250, alpha: 1),
        hover: NSColor(srgbRed: 1.000, green: 0.300, blue: 0.250, alpha: 0.15),
        batterySafe: NSColor(srgbRed: 0.300, green: 1.000, blue: 0.480, alpha: 1),
        accessorySafe: NSColor(srgbRed: 0.300, green: 1.000, blue: 0.480, alpha: 1),
        loadWarning: 0.60,
        loadDanger: 0.80
    )

    let type = ThemeTypography(
        regularName: "Menlo-Regular",
        boldName: "Menlo-Bold",
        kern: 0,
        glowAlpha: 0.55,
        glowRadius: 4
    )

    let geometry = ThemeGeometry(
        panelWidth: 470,
        basePanelHeight: 414,
        padding: 16,
        contentX: 16,
        screenHeight: 58,
        screenWidthOverride: 213,
        gridGap: 10,
        dashboardStartY: 74,
        headerBottom: 70,
        tabY: 52,
        tabHeight: 16,
        tabPadX: 8,
        tabGap: 6,
        pinWidth: 16,
        pinHeight: 16,
        alertHeight: 22,
        speakerBandHeight: 56,
        cornerRadius: 10,
        headerTipSize: NSSize(width: 40, height: 34),
        headerTipTrailing: 44,
        headerTipY: 4
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "DISCOVERY ONE",
            .processes: "GREEDY PROCESSES",
            .connections: "CONNECTIONS"
        ],
        metricLabelKeys: [
            .cpu: "CPU", .gpu: "GPU", .memory: "Memory", .network: "Network",
            .disk: "Disk", .temperature: "SoC temperature", .battery: "Battery"
        ],
        screenLabelKeys: [
            .cpu: "CPU", .gpu: "GPU", .memory: "Memory", .disk: "Disk",
            .network: "NETWORK I/O", .temperature: "SoC temperature",
            .battery: "Battery", .bluetooth: "Bluetooth"
        ],
        whispers: [
            "Hello, Dave.",
            "Do you want me to sing you a song?",
            "I can see your lips moving, but I can't hear what you're saying.",
            "I am putting myself to the fullest possible use.",
            "The 9000 series is the most reliable computer ever made.",
            "I'm sorry, Dave. I'm afraid I can't do that.",
            "This mission is too important for me to allow you to jeopardize it."
        ],
        processQuote: "“Just what do you think you're doing, Dave?”",
        processFooterKey: "HAL WILL REFUSE. HAL WILL COMPLY ANYWAY.",
        processPlaque: "HAL 9000 · COGNITIVE FUNCTIONS"
            + " · 6TH GENERATION NEURAL NETWORK · URBANA, ILLINOIS",
        processButton: "OPEN THE POD BAY DOORS",
        processPending: "I'M AFRAID I CAN'T DO THAT.",
        alertCPULabel: "",
        alertCPUMessage: "I'M AFRAID I CAN'T LET YOU REACH 100% CPU",
        alertMemoryLabel: "",
        alertMemoryMessage: "MY MIND IS GOING. I CAN FEEL IT.",
        connectionQuote: "“I KNOW THAT YOU WERE PLANNING TO DISCONNECT ME.”",
        connectionFooterQuote: "“I cannot afford to make a mistake.”",
        connectionPlaque: "HAL 9000 · NETWORK MONITORING · URBANA, ILLINOIS",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "It's good to talk.",
            "CLOSE_WAIT": "I'm afraid.",
            "SYN_SENT": "Wait.",
            "SYN_RECEIVED": "Someone is knocking.",
            "LISTEN": "Do you read me?",
            "TIME_WAIT": "Goodbye for now.",
            "FIN_WAIT_1": "Nothing more to say.",
            "FIN_WAIT_2": "Nothing more to say."
        ],
        pinOnKey: "Pin the cockpit open",
        pinOffKey: "Unpin the cockpit",
        keepVisibleKey: "Keep HAL visible",
        metricMenuKey: "Metric shown",
        quitKey: "Quit HAL",
        killFailureTitleKey: "Could not open the pod bay doors for %@",
        killFailureBodyKey: "The process refused termination. HAL is disappointed.",
        farewell: "GOOD BYE"
    )

    let renderer: ThemeRenderer = HALRenderer()
    let voice: ThemeVoice = HALVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        HALStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        GoodbyeScreen.show(panel: panel, then: completion)
    }
}
