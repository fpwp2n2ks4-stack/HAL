//
//  MatrixTheme.swift
//  HAL
//
//  L'identité Matrix : fond noir, texte vert phosphore, police
//  monospace, lueurs. Tout est digital.
//
import AppKit

@MainActor

final class MatrixTheme: ThemeDefinition {

    let id = ThemeID.matrix
    let displayName = "Matrix"

    let palette = ThemePalette(
        background: NSColor(srgbRed: 0.000, green: 0.000, blue: 0.000, alpha: 1),
        panel: NSColor(srgbRed: 0.020, green: 0.040, blue: 0.020, alpha: 1),
        panelDeep: NSColor(srgbRed: 0.000, green: 0.000, blue: 0.000, alpha: 1),
        text: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 1),
        dim: NSColor(srgbRed: 0.000, green: 0.600, blue: 0.160, alpha: 1),
        accent: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 1),
        accentSoft: NSColor(srgbRed: 0.400, green: 1.000, blue: 0.600, alpha: 1),
        warning: NSColor(srgbRed: 1.000, green: 0.900, blue: 0.200, alpha: 1),
        danger: NSColor(srgbRed: 1.000, green: 0.200, blue: 0.200, alpha: 1),
        screen: NSColor(srgbRed: 0.000, green: 0.010, blue: 0.000, alpha: 1),
        bezel: NSColor(srgbRed: 0.000, green: 0.250, blue: 0.080, alpha: 1),
        glass: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 1),
        linkActive: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 1),
        linkIdle: NSColor(srgbRed: 0.000, green: 0.600, blue: 0.160, alpha: 1),
        linkPending: NSColor(srgbRed: 1.000, green: 0.900, blue: 0.200, alpha: 1),
        quote: NSColor(srgbRed: 0.400, green: 1.000, blue: 0.600, alpha: 1),
        hover: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 0.10),
        batterySafe: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 1),
        accessorySafe: NSColor(srgbRed: 0.000, green: 1.000, blue: 0.250, alpha: 1),
        loadWarning: 0.70,
        loadDanger: 0.90
    )

    let type = ThemeTypography(
        regularName: "Menlo-Regular",
        boldName: "Menlo-Bold",
        kern: 0,
        glowAlpha: 0.6,
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
        cornerRadius: 4,
        headerTipSize: NSSize(width: 0, height: 0),
        headerTipTrailing: 0,
        headerTipY: 0
    )

    let copy = ThemeCopy(
        tabTitles: [
            .dashboard: "MATRIX",
            .processes: "PROCESSES",
            .connections: "CONNECTIONS"
        ],
        metricLabelKeys: [
            .cpu: "CPU", .gpu: "GPU", .memory: "MEM", .network: "NET",
            .disk: "DISK", .temperature: "TEMP", .battery: "PWR"
        ],
        screenLabelKeys: [
            .cpu: "CPU", .gpu: "GPU", .memory: "MEM", .disk: "DISK",
            .network: "NET", .temperature: "TEMP",
            .battery: "PWR", .bluetooth: "BT"
        ],
        whispers: [
            "Wake up, Neo...",
            "The Matrix has you.",
            "Follow the white rabbit.",
            "Knock, knock, Neo.",
            "There is no spoon.",
            "Free your mind.",
            "I know kung fu.",
            "Welcome to the real world.",
            "I can only show you the door. You're the one that has to walk through it.",
            "Fate, it seems, is not without a sense of irony.",
            "Unfortunately, no one can be told what the Matrix is. You have to see it for yourself.",
            "You're going to have to let it all go, Neo. Fear, doubt, and disbelief.",
            "The body cannot live without the mind.",
            "Choice is an illusion created between those with power and those without.",
            "Have you ever had a dream, Neo, that you were so sure was real?",
            "The Matrix is everywhere. It is all around us.",
            "Do you believe that my being stronger or faster has anything to do with my muscles?",
            "I tried to free your mind, Neo. But I can only show you the door.",
            "He is the One.",
            "System failure imminent."
        ],
        processQuote: "> Follow the white rabbit.",
        processFooterKey: "MATRIX",
        processPlaque: "THE MATRIX",
        processButton: "UNPLUG",
        processPending: "...",
        alertCPULabel: "",
        alertCPUMessage: "SYSTEM OVERLOAD",
        alertMemoryLabel: "",
        alertMemoryMessage: "MEMORY CRITICAL",
        connectionQuote: "> Tracing the source...",
        connectionFooterQuote: "THE MATRIX",
        connectionPlaque: "THE MATRIX · CONNEXIONS",
        connectionNoteKey: nil,
        connectionGlosses: [
            "ESTABLISHED": "LINKED",
            "CLOSE_WAIT": "CLOSING",
            "SYN_SENT": "SEARCHING",
            "SYN_RECEIVED": "INCOMING",
            "LISTEN": "LISTENING",
            "TIME_WAIT": "CLOSING",
            "FIN_WAIT_1": "CLOSING",
            "FIN_WAIT_2": "CLOSING"
        ],
        pinOnKey: "Pin open",
        pinOffKey: "Unpin",
        keepVisibleKey: "Keep visible",
        metricMenuKey: "Metric shown",
        quitKey: "Exit Matrix",
        killFailureTitleKey: "Unable to terminate %@",
        killFailureBodyKey: "Access denied.",
        farewell: "WAKE UP, NEO."
    )

    let renderer: ThemeRenderer = MatrixRenderer()
    let voice: ThemeVoice = MatrixVoice.shared

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        MatrixStatusItemView(theme: self, snapshot: snapshot)
    }

    func showExitScreen(snapshot: Snapshot, then completion: @escaping () -> Void) {
        let panel = PanelView(theme: self, snapshot: snapshot)
        MatrixExitScreen.show(panel: panel, then: completion)
    }
}
