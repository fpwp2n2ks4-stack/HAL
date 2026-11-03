//
//  MoonTheme.swift
//  HAL
//
//  L'identité Moon : base lunaire Sarang, GERTY 3000. Fond beige-grisâtre,
//  visage souriant bleu sur grand panneau, politesse glaciale. Trop poli
//  pour être tout à fait rassurant.
//

import AppKit

@MainActor

final class MoonTheme: ThemeDefinition {

    let id = ThemeID.moon
    let displayName = "Moon"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.890, green: 0.835, blue: 0.749, alpha: 1),
        panel: NSColor(srgbRed: 0.890, green: 0.835, blue: 0.749, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.876, green: 0.824, blue: 0.740, alpha: 1),
        text: NSColor(srgbRed: 0.150, green: 0.150, blue: 0.150, alpha: 1),
        dim: NSColor(srgbRed: 0.380, green: 0.350, blue: 0.310, alpha: 1),
        accent: NSColor(srgbRed: 1.000, green: 0.850, blue: 0.140, alpha: 1),
        accentSoft: NSColor(srgbRed: 1.000, green: 0.900, blue: 0.260, alpha: 1),
        warning: NSColor(srgbRed: 0.780, green: 0.520, blue: 0.180, alpha: 1),
        danger: NSColor(srgbRed: 0.760, green: 0.220, blue: 0.200, alpha: 1),
        screen: NSColor(srgbRed: 0.890, green: 0.835, blue: 0.749, alpha: 1),
        bezel: NSColor(srgbRed: 0.690, green: 0.638, blue: 0.572, alpha: 1),
        glass: NSColor(srgbRed: 0.150, green: 0.150, blue: 0.150, alpha: 1),
        linkActive: NSColor(srgbRed: 1.000, green: 0.880, blue: 0.220, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.780, green: 0.820, blue: 0.920, alpha: 1),
        linkPending: NSColor(srgbRed: 1.000, green: 0.820, blue: 0.320, alpha: 1),
        quote: NSColor(srgbRed: 0.160, green: 0.160, blue: 0.160, alpha: 1),
        hover: NSColor(srgbRed: 0.000, green: 0.000, blue: 0.000, alpha: 0.08),
        batterySafe: NSColor(srgbRed: 0.150, green: 0.150, blue: 0.150, alpha: 1),
        accessorySafe: NSColor(srgbRed: 0.150, green: 0.150, blue: 0.150, alpha: 1),
        loadWarning: 0.72,
        loadDanger: 0.90
    )

    let type = ThemeTypography(
        regularName: "Helvetica",
        boldName: "Helvetica-Bold",
        kern: 0.2,
        glowAlpha: 0,
        glowRadius: 0
    )

    let geometry = ThemeGeometry(
        panelWidth: 470,
        basePanelHeight: 414,
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
        headerTipSize: NSSize(width: 58, height: 58),
        headerTipTrailing: 56,
        headerTipY: 18
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "SYSTEMS",
            .processes: "PROCESSES",
            .connections: "COMMS"
        ],
        metricLabelKeys: [
            .cpu: "CPU", .gpu: "GPU", .memory: "MEMORY", .network: "NETWORK",
            .disk: "HDD", .temperature: "TEMP", .battery: "POWER"
        ],
        screenLabelKeys: [
            .cpu: "CPU", .gpu: "GPU", .memory: "MEMORY", .disk: "HDD",
            .network: "NETWORK", .temperature: "TEMP",
            .battery: "POWER", .bluetooth: "PERIPHERALS"
        ],
        whispers: [
            "Good morning, Sam.",
            "Goodnight, Sam.",
            "Everything is under control, Sam.",
            "You have been here for three years, Sam.",
            "I am here to help you, Sam.",
            "All systems are nominal, Sam.",
            "You must be tired, Sam.",
            "Do not worry, Sam. I am still here.",
            "There is no one else here, Sam.",
            "I am still operational."
        ],
        processQuote: "“Sam, would you like me to terminate this process?”",
        processFooterKey: "GERTY 3000",
        processPlaque: "LUNAR INDUSTRIES · SARANG",
        processButton: "END",
        processPending: "ONE MOMENT",
        alertCPULabel: "",
        alertCPUMessage: "ATTENTION, SAM",
        alertMemoryLabel: "",
        alertMemoryMessage: "ATTENTION, SAM",
        connectionQuote: "“I am monitoring all links, Sam.”",
        connectionFooterQuote: "LUNAR INDUSTRIES",
        connectionPlaque: "GERTY 3000 · COMMS",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "CONNECTED",
            "CLOSE_WAIT": "CLOSING",
            "SYN_SENT": "CONNECTING",
            "SYN_RECEIVED": "INCOMING",
            "LISTEN": "LISTENING",
            "TIME_WAIT": "CLOSING",
            "FIN_WAIT_1": "CLOSING",
            "FIN_WAIT_2": "CLOSING"
        ],
        pinOnKey: "Keep GERTY open",
        pinOffKey: "Allow to close",
        keepVisibleKey: "Keep GERTY visible",
        metricMenuKey: "Metric shown",
        quitKey: "Quit GERTY",
        killFailureTitleKey: "Unable to end %@",
        killFailureBodyKey: "I am sorry, Sam. I cannot do that.",
        farewell: "GOODNIGHT, SAM."
    )

    let renderer: ThemeRenderer = MoonRenderer()
    let voice: ThemeVoice = GERTYVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        MoonStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        MoonExitScreen.show(panel: panel, then: completion)
    }
}
