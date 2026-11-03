//
//  PanelView.swift
//  HAL
//
//  Le panneau commun : un seul cockpit, un seul jeu d'interactions. Le
//  thème fournit le dessin (renderer), les mots (copy), la géométrie et la
//  voix ; cette vue ne connaît que des `Snapshot`, des onglets et des
//  zones cliquables.
//
//    Onglet 1 — la synthèse des huit métriques et la bande son.
//    Onglet 2 — les processus les plus gourmands.
//    Onglet 3 — les connexions réseau, entrantes et sortantes.
//

import AppKit

final class PanelView: NSView {

    let theme: ThemeDefinition

    var snapshot: Snapshot {
        didSet {
            let wanted = panelHeight
            if abs(wanted - frame.height) > 1 {
                frame.size.height = wanted
                popover?.contentSize = NSSize(width: frame.width, height: wanted)
            }
            // Infobulle de l'état : une réplique différente à chaque relevé.
            headerTipView.toolTip = theme.copy.randomWhisper()
            needsDisplay = true
        }
    }

    weak var popover: NSPopover?
    var onKillProcess: ((ProcessUsage) -> Void)?

    /// L'état est-il épinglé ? Épinglé, il ne se referme plus au clic
    /// extérieur. C'est l'hôte (`AppDelegate`) qui applique la conséquence ;
    /// le panneau porte l'état et le signale.
    var isPinned = false {
        didSet { needsDisplay = true }
    }

    var onTogglePin: ((Bool) -> Void)?

    /// Zone cliquable de la punaise / du verrou, mémorisée au dessin.
    var pinRect: NSRect = .zero

    // MARK: - Onglets

    enum Tab: Int, CaseIterable {
        case dashboard
        case processes
        case connections
    }

    var tab: Tab = .dashboard {
        didSet { needsDisplay = true }
    }

    /// Une ligne de processus, avec ses zones cliquables mémorisées au
    /// dessin.
    struct ProcessRow {
        let process: ProcessUsage
        let rowRect: NSRect
        let buttonRect: NSRect
        let killable: Bool
    }

    var processRows: [ProcessRow] = []
    var hoveredRow: Int?

    /// Demande d'autorisation en cours, indexée par PID : le thème affiche
    /// son rituel, puis le processus est terminé quand même.
    var pendingReplies: [Int32: Date] = [:]

    /// Phase de clignotement de l'alerte CPU (0...39).
    var alertTick = 0

    /// Le curseur était-il sur l'œil / l'insigne au dernier mouvement ?
    /// Sert à ne parler qu'à l'entrée dans la zone.
    var wasOverHeader = false

    /// Alarme mémoire : phase de clignotement et instant où la charge est
    /// passée au-dessus du seuil — le clignotement ralentit ensuite.
    private var memoryAlertTick = 0
    private var memoryHotSince: Date?

    /// Zones cliquables des onglets, mémorisées au dessin.
    var tabRects: [Tab: NSRect] = [:]

    /// Dernière pochette décodée, gardée avec les données qui l'ont
    /// produite : `Data` → `NSImage` coûte un décodage, inutile à chaque
    /// frame alors que la piste ne change qu'à la marge.
    var artworkCache: (data: Data, image: NSImage)?

    // MARK: - Cycle de vie

    init(theme: ThemeDefinition, snapshot: Snapshot) {
        self.theme = theme
        self.snapshot = snapshot
        super.init(frame: NSRect(x: 0, y: 0,
                                 width: theme.geometry.panelWidth,
                                 height: theme.geometry.basePanelHeight))
        wantsLayer = true

        headerTipView.frame = theme.geometry.headerTipRect(in: theme.geometry.panelWidth)
        headerTipView.toolTip = theme.copy.randomWhisper()
        addSubview(headerTipView)

        // Invisible tant qu'aucun état n'est survolé : elle ne sert qu'à
        // porter l'infobulle.
        stateTipView.isHidden = true
        addSubview(stateTipView)

        pinTipView.toolTip = loc(theme.copy.pinOnKey)
        pinTipView.isHidden = true
        addSubview(pinTipView)

        // La hauteur inclut les bandes d'alarme déjà actives au premier
        // dessin : sinon le panneau naît tronqué quand la machine chauffe.
        frame.size.height = panelHeight
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    // MARK: - Porteurs d'infobulle

    /// L'œil (HAL) ou l'insigne (LCARS) de l'en-tête porte son infobulle.
    /// Depuis ce SDK, la seule façon d'en attacher à une zone dessinée à la
    /// main est une sous-vue porteuse de `toolTip` qui se déclare survolable.
    lazy var headerTipView = HoverTipView(frame: .zero)

    /// Porteur d'infobulle des états TCP, dans l'onglet connexions.
    let stateTipView = HoverTipView(frame: .zero)

    /// Porteur d'infobulle de la punaise / du verrou.
    let pinTipView = HoverTipView(frame: .zero)

    /// Rectangles des zones d'état survolées, avec l'état correspondant :
    /// rempli au dessin, lu au survol.
    var connectionStateRects: [(rect: NSRect, state: String)] = []

    /// La séquence du thème : il refuse (ou demande une autorisation),
    /// puis obéit quand même.
    func performProcessTermination(_ process: ProcessUsage) {
        pendingReplies[process.pid] = Date()
        needsDisplay = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000) // 1.6 secondes
            pendingReplies.removeValue(forKey: process.pid)
            onKillProcess?(process)
        }
    }

    // MARK: - Dessin

    override func draw(_ dirtyRect: NSRect) {
        theme.renderer.drawBackground(in: self)
        theme.renderer.drawHeader(in: self)
        drawTabs()

        var cursorY = theme.geometry.dashboardStartY
        if cpuIsCritical {
            drawAlert(.cpu, at: &cursorY)
        }
        if memoryIsCritical {
            drawAlert(.memory, at: &cursorY)
        } else {
            memoryHotSince = nil
        }

        switch tab {
        case .dashboard: drawDashboard(at: &cursorY)
        case .processes: drawProcessesTab(at: &cursorY)
        case .connections: drawConnectionsTab(at: &cursorY)
        }

        theme.renderer.drawScanlines(in: self)
    }

    var cpuIsCritical: Bool { snapshot.cpu.total >= 90 }
    var memoryIsCritical: Bool { snapshot.memory.fraction >= 0.90 }

    // MARK: - Onglets

    /// Mesure les pastilles puis délègue leur dessin au thème : la
    /// composition (pastille pleine, onglet actif, verrou) est une affaire
    /// d'identité, la zone cliquable une affaire de noyau.
    private func drawTabs() {
        tabRects.removeAll()
        let geometry = theme.geometry
        var cursorX = geometry.contentX

        for entry in Tab.allCases {
            let title = theme.copy.tabTitles[entry] ?? ""
            let attrs = theme.type.attributes(9, color: theme.palette.text, bold: true)
            let size = title.size(withAttributes: attrs)
            let rect = NSRect(x: cursorX, y: geometry.tabY,
                              width: size.width + geometry.tabPadX * 2,
                              height: geometry.tabHeight)
            tabRects[entry] = rect
            cursorX += rect.width + geometry.tabGap
        }

        pinRect = NSRect(x: bounds.width - geometry.padding - geometry.pinWidth,
                         y: geometry.tabY,
                         width: geometry.pinWidth, height: geometry.pinHeight)
        theme.renderer.drawTabs(in: self, tabRects: tabRects, pinRect: pinRect)
    }

    // MARK: - Alertes

    /// « I'm afraid I can't let you reach 100% CPU » ou « RED ALERT » : le
    /// noyau décide du déclenchement et du rythme, le thème du dessin.
    private func drawAlert(_ kind: AlertKind, at cursorY: inout CGFloat) {
        let visible: Bool
        switch kind {
        case .cpu:
            alertTick = (alertTick + 1) % 40
            visible = alertTick < 28
        case .memory:
            let factor: Double
            if let since = memoryHotSince {
                factor = min(3.0, since.timeIntervalSinceNow / -25 + 1)
            } else {
                memoryHotSince = Date()
                factor = 1
            }
            memoryAlertTick = (memoryAlertTick + 1) % Int(40 * factor)
            visible = memoryAlertTick < Int(28 * factor)
        }

        let label = kind == .cpu ? theme.copy.alertCPULabel : theme.copy.alertMemoryLabel
        let message = kind == .cpu ? theme.copy.alertCPUMessage : theme.copy.alertMemoryMessage
        let rect = NSRect(x: theme.geometry.contentX, y: cursorY,
                          width: contentW, height: theme.geometry.alertHeight)
        theme.renderer.drawAlert(in: self, spec: AlertSpec(
            rect: rect, kind: kind, label: loc(label), message: loc(message), visible: visible))
        cursorY += 30
    }
}
