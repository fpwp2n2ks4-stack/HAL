//
//  ArkTheme.swift
//  HAL
//
//  L'identité The Ark : le vaisseau-colonie Ark One, cent ans après le
//  départ de la Terre. Palette monochrome froide — bleu spatial, blanc de
//  console, cyan des écrans — relevée d'un ambre d'alarme. Les répliques
//  cultes restent en anglais : ce sont les mots de l'équipage, pas des
//  chaînes d'interface.
//

import AppKit

@MainActor

final class ArkTheme: ThemeDefinition {

    let id = ThemeID.ark
    let displayName = "The Ark"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.012, green: 0.020, blue: 0.031, alpha: 1),
        panel: NSColor(srgbRed: 0.039, green: 0.059, blue: 0.078, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.020, green: 0.031, blue: 0.043, alpha: 1),
        text: NSColor(srgbRed: 0.878, green: 0.933, blue: 0.969, alpha: 1),
        dim: NSColor(srgbRed: 0.353, green: 0.463, blue: 0.541, alpha: 1),
        accent: NSColor(srgbRed: 0.263, green: 0.831, blue: 0.929, alpha: 1),
        accentSoft: NSColor(srgbRed: 0.604, green: 0.925, blue: 1.000, alpha: 1),
        warning: NSColor(srgbRed: 0.973, green: 0.678, blue: 0.259, alpha: 1),
        danger: NSColor(srgbRed: 0.937, green: 0.290, blue: 0.267, alpha: 1),
        screen: NSColor(srgbRed: 0.027, green: 0.047, blue: 0.067, alpha: 1),
        bezel: NSColor(srgbRed: 0.118, green: 0.192, blue: 0.251, alpha: 1),
        glass: NSColor(srgbRed: 0.925, green: 0.976, blue: 1.000, alpha: 1),
        linkActive: NSColor(srgbRed: 0.263, green: 0.831, blue: 0.929, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.353, green: 0.463, blue: 0.541, alpha: 1),
        linkPending: NSColor(srgbRed: 0.973, green: 0.678, blue: 0.259, alpha: 1),
        quote: NSColor(srgbRed: 0.651, green: 0.867, blue: 0.925, alpha: 1),
        hover: NSColor(srgbRed: 0.263, green: 0.831, blue: 0.929, alpha: 0.10),
        batterySafe: NSColor(srgbRed: 0.263, green: 0.831, blue: 0.929, alpha: 1),
        accessorySafe: NSColor(srgbRed: 0.604, green: 0.925, blue: 1.000, alpha: 1),
        loadWarning: 0.70,
        loadDanger: 0.88
    )

    let type = ThemeTypography(
        regularName: "AvenirNextCondensed-Regular",
        boldName: "AvenirNextCondensed-DemiBold",
        kern: 1.0,
        glowAlpha: 0.18,
        glowRadius: 3
    )

    let geometry = ThemeGeometry(
        panelWidth: 500,
        basePanelHeight: 426,
        padding: 18,
        contentX: 18,
        screenHeight: 56,
        screenWidthOverride: nil,
        gridGap: 10,
        dashboardStartY: 88,
        headerBottom: 84,
        tabY: 66,
        tabHeight: 18,
        tabPadX: 10,
        tabGap: 6,
        pinWidth: 38,
        pinHeight: 18,
        alertHeight: 22,
        speakerBandHeight: 54,
        cornerRadius: 5,
        headerTipSize: NSSize(width: 74, height: 48),
        headerTipTrailing: 86,
        headerTipY: 12
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "ARK ONE",
            .processes: "CREW OPS",
            .connections: "COMMS"
        ],
        metricLabelKeys: [
            .cpu: "Core output", .gpu: "Ops processor", .memory: "Life support",
            .network: "Comms link", .disk: "Data archive",
            .temperature: "Thermal load", .battery: "Power cell"
        ],
        screenLabelKeys: [
            .cpu: "CORE", .gpu: "OPS", .memory: "LIFE SUPPORT",
            .disk: "ARCHIVE", .network: "COMMS", .temperature: "THERMAL",
            .battery: "POWER", .bluetooth: "CREW LINK"
        ],
        whispers: [
            "Everyone wanted to be on this ship.",
            "We weren't supposed to be awake.",
            "Every single person matters.",
            "Hoping for forever.",
            "Everybody wins.",
            "We don't kill our own.",
            "It will be over soon.",
            "I told you not to come.",
            "We can't save everyone.",
            "This is Ark One.",
            "Ark One, do you copy?",
            "All hands to your stations.",
            "Proxima Centauri B. Our new home.",
            "The mission comes first.",
            "One ship. One crew. One future.",
            "Trust the mission.",
            "Stay on course."
        ],
        processQuote: "“We don't kill our own.”",
        processFooterKey: "ARK ONE · CREW MANIFEST · CURRENT USER ONLY",
        processPlaque: "ARK PROGRAM · ARK ONE · DEEP SPACE TRANSIT",
        processButton: "ABORT",
        processPending: "COMMAND LOCKED",
        alertCPULabel: "WARNING",
        alertCPUMessage: "CORE OUTPUT CRITICAL",
        alertMemoryLabel: "LIFE SUPPORT",
        alertMemoryMessage: "OXYGEN RESERVE CRITICAL",
        connectionQuote: "“Ark One, do you copy?”",
        connectionFooterQuote: "“One ship. One crew. One future.”",
        connectionPlaque: "ARK ONE · CENT-COM · CONNECTION LOG",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "CHANNEL OPEN",
            "CLOSE_WAIT": "CLOSING",
            "SYN_SENT": "HAILING",
            "SYN_RECEIVED": "SIGNAL FOUND",
            "LISTEN": "LISTENING",
            "TIME_WAIT": "CHANNEL CLOSED",
            "FIN_WAIT_1": "CLOSING",
            "FIN_WAIT_2": "CLOSING"
        ],
        pinOnKey: "Lock Ark One open",
        pinOffKey: "Release Ark One",
        keepVisibleKey: "Keep Ark One visible",
        metricMenuKey: "Telemetry shown",
        quitKey: "End mission",
        killFailureTitleKey: "Unable to terminate %@",
        killFailureBodyKey: "Ark protocol denies this command.",
        farewell: "ARK ONE, OUT."
    )

    let renderer: ThemeRenderer = ArkRenderer()
    let voice: ThemeVoice = ArkVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        ArkStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        ArkExitScreen.show(panel: panel, then: completion)
    }
}
