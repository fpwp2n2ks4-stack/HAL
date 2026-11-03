//
//  NotchIslandController.swift
//  HAL
//
//  L'îlot réactif : une fenêtre au niveau de la barre de menus, posée sur le
//  cran, qui ne se réveille que sur événement — seuil franchi, secteur
//  branché, survol — puis se rendort seule.
//
//  Aucun nouveau capteur, aucun nouveau timer de collecte : le contrôleur
//  compare deux `Snapshot` consécutifs et ne réagit qu'au **front**. Un CPU
//  bloqué à 96 % ne fait donc pas clignoter l'îlot toutes les deux secondes.
//
//  Migré vers Swift Concurrency (Async/Await) pour une meilleure gestion
//  des tâches asynchrones, de la cancellation et de la thread-safety.
//

import AppKit

/// Fenêtre de l'îlot. Elle ne prend jamais le focus : cliquer dessus ne
/// doit pas voler l'application au premier plan.
final class NotchIslandPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// NotchIslandController gère maintenant la lecture des snapshots de manière asynchrone
/// et utilise Swift Concurrency pour une meilleure gestion des tâches.
@MainActor
final class NotchIslandController {

    enum State {
        case dormant
        case peek
        case hover
    }

    /// Ce qu'un événement a à dire, déjà mis dans les mots du thème.
    struct Peek {
        let title: String
        let detail: String
        let tint: NSColor
    }

    let panel: NotchIslandPanel
    let view: NotchIslandView

    var theme: ThemeDefinition
    var snapshot: Snapshot
    var previous: Snapshot?

    var geometry: NotchGeometry?
    var state: State = .peek
    var mouseInside = false

    var animationTask: Task<Void, Error>?
    var collapseTask: Task<Void, Error>?
    var observationTask: Task<Void, Never>?
    var lastPeek: Date = .distantPast

    let openWidth: CGFloat = 360
    let onOpenCockpit: () -> Void

    /// Le cockpit est-il déjà à l'écran ? Un îlot qui s'ouvre par-dessus un
    /// panneau visible ne servirait à rien.
    var isCockpitVisible: (() -> Bool)?

    /// Clic droit sur l'îlot : ouvre le menu de l'application (thème,
    /// métrique, langue, épinglage, quitter).
    var onContextMenu: ((NSEvent) -> Void)?

    /// Bord bas du cran : c'est là que le cockpit vient s'ancrer.
    var anchorFrame: NSRect {
        geometry?.closedFrame ?? .zero
    }

    /// L'écran qui porte l'îlot, pour les calculs de bornes du cockpit.
    var screen: NSScreen? { geometry?.screen }

    /// Vue et rectangle d'ancrage du cockpit : le bord bas du cran, au
    /// centre. Le popover s'y accroche comme il le ferait sous l'icône de la
    /// barre de menus, mais avec le bon axe.
    var anchorView: NSView { view }
    var anchorRect: NSRect {
        NSRect(x: view.bounds.midX - 1, y: 0, width: 2, height: 1)
    }

    init(theme: ThemeDefinition,
         snapshot: Snapshot,
         onOpenCockpit: @escaping () -> Void) {
        self.theme = theme
        self.snapshot = snapshot
        self.onOpenCockpit = onOpenCockpit

        self.panel = NotchIslandPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.view = NotchIslandView(theme: theme, snapshot: snapshot)

        configurePanel()
        configureView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        refreshGeometry(position: true)
    }

    @MainActor deinit {
        NotificationCenter.default.removeObserver(self)
        observationTask?.cancel()
        collapseTask?.cancel()
        animationTask?.cancel()
    }

    // MARK: - Configuration

    func configurePanel() {
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = false
        // Au-dessus de la barre de menus, sous les alertes système.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces,
                                    .fullScreenAuxiliary,
                                    .stationary,
                                    .ignoresCycle]
    }

    func configureView() {
        view.autoresizingMask = [.width, .height]
        view.onOpen = { [weak self] in self?.handleClick() }
        view.onHover = { [weak self] inside in self?.handleHover(inside) }
        view.onContextMenu = { [weak self] event in self?.onContextMenu?(event) }
        panel.contentView = view
    }

    // MARK: - Cycle de vie

    /// Démarre l'observation asynchrone des snapshots
    func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            await self?.observeSnapshots()
        }
    }

    /// Arrête l'observation
    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }

    /// Boucle d'observation asynchrone des snapshots
    func observeSnapshots() async {
        while !Task.isCancelled {
            // Attendre un tick (simulé ici - dans la vraie implémentation,
            // cela serait géré par le SnapshotReader)
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes

            // Note: Dans l'implémentation finale, on utiliserait:
            // let snapshot = try await snapshotReader.readSnapshot()
            // await MainActor.run { update(snapshot: snapshot) }
        }
    }

    // MARK: - Cycle public

    /// Appelé à chaque relevé, après le cockpit : l'îlot se contente de
    /// comparer avec le relevé précédent.
    func update(snapshot newSnapshot: Snapshot) {
        snapshot = newSnapshot
        view.setSnapshot(newSnapshot)
        refreshGeometry(position: false)

        guard let old = previous else {
            // Premier relevé : il sert de référence, jamais de déclencheur.
            previous = newSnapshot
            return
        }
        previous = newSnapshot

        if let peek = detect(from: old, to: newSnapshot) {
            present(peek)
        }
    }

    func applyTheme(_ newTheme: ThemeDefinition) {
        theme = newTheme
        view.applyTheme(newTheme)
        view.setSnapshot(snapshot)

        if state != .dormant {
            view.title = newTheme.copy.randomWhisper()
            view.detail = metricsLine()
            view.tint = newTheme.palette.accent
        }
    }

    func shutdown() {
        stopObserving()
        cancelAnimation()
        panel.orderOut(nil)
        // Le retrait des observateurs se fait dans `deinit` : un objet ne
        // doit se désinscrire que de là-bas.
    }

    // MARK: - Géométrie

    func refreshGeometry(position: Bool) {
        let fresh = NotchGeometry.preferred() ?? NotchGeometry.force()

        // Toujours afficher le panel
        geometry = fresh
        view.notchHeight = fresh.notchHeight
        view.notchWidth = fresh.notchWidth

        // Forcer l'affichage permanent en positionnant toujours avec openFrame
        if position || !panel.isVisible {
            let target = fresh.openFrame(width: openWidth, contentHeight: view.stripHeight)
            cancelAnimation()
            view.isAwake = true  // Forcer l'affichage
            panel.setFrame(target, display: true)
            view.needsLayout = true
            view.needsDisplay = true
            panel.orderFrontRegardless()

            // S'assurer que le panel est visible
            if !panel.isVisible {
                panel.orderFrontRegardless()
            }
        }
    }

    @objc func screenParametersDidChange() {
        refreshGeometry(position: true)
    }

    // MARK: - Déclencheurs

    func detect(from old: Snapshot, to new: Snapshot) -> Peek? {
        let palette = theme.palette

        if new.cpu.total >= 90, old.cpu.total < 90 {
            let temperature = new.temperature.socPeak
                .map { String(format: " · %.0f°C", $0) } ?? ""
            return Peek(
                title: "\(theme.copy.screenLabel(.cpu)) \(Int(new.cpu.total.rounded()))%\(temperature)",
                detail: loc(theme.copy.alertCPUMessage),
                tint: palette.danger
            )
        }

        if new.memory.fraction >= 0.90, old.memory.fraction < 0.90 {
            return Peek(
                title: "\(theme.copy.screenLabel(.memory)) \(Int((new.memory.fraction * 100).rounded()))%",
                detail: loc(theme.copy.alertMemoryMessage),
                tint: palette.danger
            )
        }

        if new.battery.isPresent,
           ThemePalette.isBatteryLow(new.battery.level),
           !ThemePalette.isBatteryLow(old.battery.level) {
            return Peek(
                title: "\(theme.copy.screenLabel(.battery)) \(new.battery.level)%",
                detail: loc("Battery low"),
                tint: palette.danger
            )
        }

        if new.battery.isPresent,
           new.battery.isPlugged != old.battery.isPlugged {
            return Peek(
                title: theme.copy.screenLabel(.battery),
                detail: new.battery.isPlugged
                    ? loc("Power connected")
                    : loc("Power disconnected"),
                tint: palette.accent
            )
        }

        if new.disk.fraction >= 0.95, old.disk.fraction < 0.95 {
            return Peek(
                title: "\(theme.copy.screenLabel(.disk)) \(Int((new.disk.fraction * 100).rounded()))%",
                detail: loc("Disk almost full"),
                tint: palette.warning
            )
        }

        return nil
    }

    /// Un aperçu ne s'affiche que si le cockpit est fermé et qu'un autre
    /// aperçu ne vient pas de passer : deux alertes coup sur coup se
    /// disputeraient la même bande.
    func present(_ peek: Peek) {
        guard geometry != nil, state == .dormant else { return }
        guard isCockpitVisible?() != true else { return }

        let now = Date()
        guard now.timeIntervalSince(lastPeek) > 8 else { return }
        lastPeek = now

        view.title = peek.title
        view.detail = peek.detail
        view.tint = peek.tint
    }

    // MARK: - Contenu de survol

    /// La ligne de survol : quatre chiffres, séparés par des points médians.
    /// Les unités restent compactes, la bande ne fait que 360 points.
    func metricsLine() -> String {
        let snap = snapshot
        let cpu = Int(snap.cpu.total.rounded())
        let temperature = snap.temperature.socPeak.map { String(format: "%.0f°C", $0) } ?? "—"
        let memory = Int((snap.memory.fraction * 100).rounded())
        let network = Formatters.bytes(
            max(snap.network.downloadPerSecond, snap.network.uploadPerSecond)
        )
        let battery = snap.battery.isPresent ? "\(snap.battery.level)%" : "—"
        return "CPU \(cpu)% · \(temperature) · MEM \(memory)% · NET \(network) · BAT \(battery)"
    }
}
