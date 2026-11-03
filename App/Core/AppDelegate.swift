//
//  AppDelegate.swift
//  HAL
//
//  Point d'entrée de l'application barre de menus. L'hôte ne connaît que
//  le theme courant : il assemble l'item de barre de menus, le popover et
//  la fenêtre flottante à partir de `ThemeManager`, et reconstruit le tout
//  quand l'utilisateur change d'identité.
//
//  Migré vers Swift Concurrency pour une meilleure gestion asynchrone.
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let themes = ThemeManager.shared
    var theme: ThemeDefinition { themes.current }

    var statusItem: NSStatusItem?
    var statusView: StatusItemView?

    var popover: NSPopover!

    /// Le panneau du cockpit. Il change d'hôte selon l'épinglage : le
    /// popover quand il est au repos, une fenêtre flottante quand il doit
    /// rester visible. Il change aussi de theme : c'est une vue neuve à
    /// chaque bascule, jamais une vue repeinte.
    var cockpitView: PanelView!

    /// Fenêtre flottante du cockpit épinglé.
    ///
    /// Un popover ne suffit pas à rester visible : dès qu'on active une
    /// autre application, macOS peut le retirer. Une vraie fenêtre de
    /// niveau flottant, elle, survit au changement d'application — c'est
    /// ce qui permet de lancer une app et de regarder le vaisseau encaisser.
    var pinnedPanel: NSPanel?

    /// L'îlot réactif posé sur le cran de l'écran. Il ne se réveille que sur
    /// événement, et n'existe que sur un écran à encoche.
    var notchIsland: NotchIslandController?

    /// Le cockpit flottant est-il accroché sous le cran plutôt que sous
    /// l'icône de la barre de menus ? Sa hauteur change avec les alarmes :
    /// l'ancre doit survivre aux recompositions.
    var cockpitAnchoredToNotch = false

    /// Surveillance du clic extérieur. `.transient` ferme le popover quand
    /// l'application est active ; un agent de barre de menus ne l'est pas
    /// toujours, donc on double le comportement par des moniteurs pour
    /// qu'un clic hors du cockpit le referme dans tous les cas.
    var localDismissMonitor: Any?
    var globalDismissMonitor: Any?

    /// Le popover du cockpit, en lecture seule.
    ///
    /// Exposé pour les vérifications automatisées (état d'épinglage,
    /// comportement du popover) : la propriété reste privée pour l'usage
    /// courant, et c'est par là qu'on observe l'effet de la punaise.
    var cockpitPopover: NSPopover? { popover }

    /// Fenêtre flottante du cockpit épinglé, en lecture seule.
    var cockpitPanel: NSPanel? { pinnedPanel }

    // MARK: - Swift Concurrency

    /// SnapshotReader pour la lecture asynchrone des métriques
    var snapshotReader: SnapshotReader?

    /// Dernier snapshot lu
    var latest: Snapshot

    /// Task d'observation des snapshots
    var observationTask: Task<Void, Never>?

    // Historique court pour lisser le débit réseau :
    // les compteurs bursty rendent le débit instantané illisible.
    var netSamples: [(Date, Double)] = []

    /// Dernière alerte CPU affichée : sans ce plafonnement, une machine
    /// longtemps au-delà de 90 % ferait clignoter l'alarme en continu.
    var lastCPUAlert: Date = .distantPast

    override init() {
        var initial = Snapshot()
        initial.battery.isPresent = true
        self.latest = initial
        super.init()
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Cycle de vie

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Agent de barre de menus uniquement : pas d'icône dans le Dock.
        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )

        setupStatusItem()
        setupPopover()

        // Initialiser le SnapshotReader de manière asynchrone
        Task(priority: .utility) { [weak self] in
            let reader = await SnapshotReader()
            self?.snapshotReader = reader
            self?.startObserving()
        }

        refresh()
        setupNotchIsland()
    }

    /// Démarre l'observation asynchrone des snapshots
    func startObserving() {
        observationTask?.cancel()
        observationTask = Task.detached(priority: .utility) { [weak self] in
            await self?.observeSnapshots()
        }
    }

    /// Boucle d'observation asynchrone
    func observeSnapshots() async {
        guard let reader = snapshotReader else { return }

        while !Task.isCancelled {
            do {
                // Lire un nouveau snapshot
                let snapshot = try await reader.readSnapshot()

                await MainActor.run {
                    self.processNewSnapshot(snapshot)
                }

                // Attendre avant le prochain tick (Interval.current est utilisé dans l'ancien code)
                try await Task.sleep(nanoseconds: UInt64(Interval.current * 1_000_000_000))

            } catch let error as ReaderError {
                Logger.error(error, category: .sensors)
                // En cas d'erreur, attendre avant de réessayer
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
            } catch {
                Logger.error(error, category: .sensors)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    /// Traite un nouveau snapshot
    func processNewSnapshot(_ snapshot: Snapshot) {
        var processedSnapshot = snapshot
        smoothNetwork(&processedSnapshot)
        latest = processedSnapshot

        statusView?.snapshot = processedSnapshot
        // L'icône cause un peu : une nouvelle réplique en infobulle à
        // chaque relevé — c'est le genre de détail qu'un ordinateur de bord
        // apprécie.
        statusView?.toolTip = theme.copy.randomWhisper()
        updateStatusItemSize()

        if cockpitIsVisible {
            cockpitView.snapshot = processedSnapshot
            // La hauteur du cockpit varie avec les bandes d'alarme : la
            // fenêtre flottante doit suivre, et rester accrochée sous
            // l'icône.
            if let panel = pinnedPanel, panel.isVisible {
                panel.setContentSize(cockpitView.frame.size)
                positionPinnedPanel(panel)
            }
        }

        // L'îlot ne reçoit que le relevé déjà lissé : il compare avec le
        // précédent et ne réagit qu'au franchissement d'un seuil.
        notchIsland?.update(snapshot: processedSnapshot)

        // Alarme CPU : le panneau hurle, et un bip discret rappelle toutes
        // les 30 s que la machine est au-delà de 90 %.
        if processedSnapshot.cpu.total >= 90,
           Date().timeIntervalSince(lastCPUAlert) > 30 {
            lastCPUAlert = Date()
            NSSound.beep()
        }
    }

    /// Interruption volontaire : le vaisseau s'éteint avant que le processus
    /// ne sorte — chaque theme a sa mort, cascade d'écrans ou mise hors
    /// service de la console.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        observationTask?.cancel()
        theme.voice.hush()
        // La fenêtre flottante passerait devant l'écran d'adieu : elle
        // s'efface pour laisser le theme mourir seul. L'îlot aussi.
        pinnedPanel?.orderOut(nil)
        notchIsland?.shutdown()
        theme.showExitScreen(snapshot: latest) {
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    // MARK: - Îlot du cran

    /// Crée l'îlot une fois le premier relevé connu : il lui faut un
    /// `Snapshot` de référence pour ne pas déclencher au lancement.
    func setupNotchIsland() {
        Task { @MainActor [weak self] in
            // Attendre que snapshotReader soit initialisé et attendre le premier snapshot
            guard let self = self else { return }
            guard let reader = self.snapshotReader else { return }
            do {
                let firstSnapshot = try await reader.readSnapshot()
                let island = NotchIslandController(theme: self.theme, snapshot: firstSnapshot) { [weak self] in
                    self?.openCockpitUnderNotch()
                }
                island.isCockpitVisible = { [weak self] in
                    self?.cockpitIsVisible ?? false
                }
                island.onContextMenu = { [weak self] event in
                    self?.showNotchContextMenu(event)
                }
                self.notchIsland = island
                self.latest = firstSnapshot
            } catch {
                Logger.error(error, category: .lifecycle)
                // En cas d'erreur, créer l'îlot avec un snapshot vide
                let island = NotchIslandController(theme: theme, snapshot: Snapshot()) { [weak self] in
                    self?.openCockpitUnderNotch()
                }
                island.isCockpitVisible = { [weak self] in
                    self?.cockpitIsVisible ?? false
                }
                island.onContextMenu = { [weak self] event in
                    self?.showNotchContextMenu(event)
                }
                notchIsland = island
            }
        }
    }

    /// Ouvre le cockpit complet sous le cran, en popover transitoire.
    ///
    /// C'est le même contrat que sous l'icône de la barre de menus : un
    /// clic à l'extérieur referme le cockpit. Le laisser épinglé d'office
    /// obligerait à viser la punaise pour retrouver le bureau, ce qui n'est
    /// pas ce qu'on attend d'un îlot qu'on vient d'effleurer.
    func openCockpitUnderNotch() {
        guard let island = notchIsland, island.anchorFrame != .zero else { return }

        cockpitView.isPinned = false
        cockpitAnchoredToNotch = true
        openPopover(anchoredTo: island)
    }

    // MARK: - Utilitaires

    /// Lisse le débit réseau sur ~6 s
    func smoothNetwork(_ snapshot: inout Snapshot) {
        let now = snapshot.date
        netSamples.append((now, snapshot.network.downloadPerSecond + snapshot.network.uploadPerSecond))
        netSamples.removeAll { now.timeIntervalSince($0.0) > 6 }

        guard netSamples.count > 1 else { return }
        let average = netSamples.reduce(0.0) { $0 + $1.1 } / Double(netSamples.count)
        let last = netSamples[netSamples.count - 1].1
        let ratio = last > 0 ? (snapshot.network.downloadPerSecond / last) : 0.5
        snapshot.network.downloadPerSecond = average * ratio
        snapshot.network.uploadPerSecond = average * (1 - ratio)
    }

    /// Rafraîchissement manuel (pour le kill process)
    func refresh() {
        Task { @MainActor in
            guard let reader = snapshotReader else { return }
            do {
                var snapshot = try await reader.readSnapshot()
                smoothNetwork(&snapshot)
                latest = snapshot

                statusView?.snapshot = snapshot
                statusView?.toolTip = theme.copy.randomWhisper()
                updateStatusItemSize()

                if cockpitIsVisible {
                    cockpitView.snapshot = snapshot
                    if let panel = pinnedPanel, panel.isVisible {
                        panel.setContentSize(cockpitView.frame.size)
                        positionPinnedPanel(panel)
                    }
                }

                notchIsland?.update(snapshot: snapshot)
            } catch {
                Logger.error(error, category: .sensors)
            }
        }
    }
}

extension AppDelegate: NSPopoverDelegate {

    /// Le popover s'est refermé, quelle qu'en soit la cause (clic extérieur,
    /// épinglage, changement d'application) : les moniteurs n'ont plus lieu
    /// d'être.
    func popoverDidClose(_ notification: Notification) {
        removeDismissMonitors()
    }
}

// Fonction helper pour la localisation (à déplacer dans un fichier dédié si nécessaire)
private func loc(_ key: String, _ arg: String = "") -> String {
    if arg.isEmpty {
        return NSLocalizedString(key, comment: "")
    } else {
        return String(format: NSLocalizedString(key, comment: ""), arg)
    }
}
