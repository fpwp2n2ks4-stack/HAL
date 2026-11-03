//
//  AppDelegate+Cockpit.swift
//  HAL
//
//  Le cockpit : panneau épinglé, popover, fenêtre flottante, moniteurs
//  de fermeture, et la fin des processus. Séparé du corps principal.
//

import AppKit

extension AppDelegate {

    // MARK: - Panneau

    func makePanelView() -> PanelView {
        let view = PanelView(theme: theme, snapshot: latest)
        view.popover = popover
        view.onKillProcess = { [weak self] process in
            self?.killProcess(process)
        }
        // La punaise du cockpit : épinglé, le panneau migre dans une
        // fenêtre flottante et ne disparaît plus au changement d'application.
        view.onTogglePin = { [weak self] pinned in
            self?.applyPin(pinned)
        }
        return view
    }

    func makeController(for view: PanelView) -> NSViewController {
        let controller = NSViewController()
        controller.view = view
        return controller
    }

    func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self

        let view = makePanelView()
        cockpitView = view
        popover.contentViewController = makeController(for: view)
        popover.contentSize = view.frame.size
    }

    /// Applique l'épinglage : le cockpit change d'hôte.
    ///
    /// Épinglé, il quitte le popover pour une fenêtre flottante de niveau
    /// `.floating`, insensible au changement d'application : on peut lancer
    /// une app et regarder le vaisseau réagir. Désépinglé, la fenêtre
    /// flottante se referme : « ne plus garder le cockpit visible » veut
    /// dire le laisser disparaître. Le prochain clic sur l'icône rouvre un
    /// popover normal.
    func applyPin(_ pinned: Bool) {
        if pinned {
            // Si le cockpit a été ouvert depuis le cran, il reste sous le
            // cran une fois épinglé : la punaise ne le fait pas sauter sous
            // l'icône de la barre de menus. Sans icône, le cran est la
            // seule ancre possible.
            showPinnedPanel(anchoredToNotch: cockpitAnchoredToNotch || statusItem == nil)
        } else {
            hidePinnedPanel()
        }
        cockpitView.needsDisplay = true
    }

    /// Le cockpit est-il visible, quel que soit son hôte ?
    var cockpitIsVisible: Bool {
        if let panel = pinnedPanel, panel.isVisible { return true }
        return popover.isShown
    }

    func openCockpit() {
        cockpitView.snapshot = latest
        if cockpitView.isPinned {
            showPinnedPanel(anchoredToNotch: cockpitAnchoredToNotch || statusItem == nil)
        } else {
            // Sans icône de barre de menus, le cran est la seule ancre.
            openPopover(anchoredTo: statusItem == nil ? notchIsland : nil)
        }
    }

    func closeCockpit() {
        pinnedPanel?.orderOut(nil)
        if popover.isShown {
            popover.performClose(nil)
        }
        removeDismissMonitors()
    }

    func openPopover(anchoredTo island: NotchIslandController? = nil) {
        guard let view = cockpitView else { return }
        // Si la vue vit encore dans l'ancienne fenêtre flottante (le
        // détachement est différé), on la lui reprend : une vue ne peut
        // pas appartenir à deux fenêtres.
        detachCockpitView()
        popover.contentViewController?.view = view
        view.snapshot = latest
        view.needsDisplay = true

        if let island {
            cockpitAnchoredToNotch = true
            popover.show(relativeTo: island.anchorRect,
                         of: island.anchorView,
                         preferredEdge: .minY)
        } else if let button = statusItem?.button {
            cockpitAnchoredToNotch = false
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        } else if let island = notchIsland, island.anchorFrame != .zero {
            // Pas d'icône de barre de menus : on s'accroche au cran.
            cockpitAnchoredToNotch = true
            popover.show(relativeTo: island.anchorRect,
                         of: island.anchorView,
                         preferredEdge: .minY)
        } else {
            return
        }

        popover.contentViewController?.view.window?.makeKey()
        installDismissMonitors()
        view.theme.voice.say(view.theme.copy.randomWhisper())
    }

    /// Un clic hors du cockpit le referme. Les moniteurs couvrent les deux
    /// cas : localement (une autre fenêtre de l'application, l'îlot) et
    /// globalement (une autre application, le bureau).
    func installDismissMonitors() {
        removeDismissMonitors()

        localDismissMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self, self.popover.isShown else { return event }
            // Le cockpit lui-même, et l'icône qui gère son propre
            // basculement, ne sont pas « à l'extérieur ».
            if event.window === self.popover.contentViewController?.view.window {
                return event
            }
            if let statusWindow = self.statusItem?.button?.window,
               event.window === statusWindow {
                return event
            }
            self.closeCockpit()
            return event
        }

        globalDismissMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.closeCockpit()
        }
    }

    func removeDismissMonitors() {
        if let monitor = localDismissMonitor {
            NSEvent.removeMonitor(monitor)
            localDismissMonitor = nil
        }
        if let monitor = globalDismissMonitor {
            NSEvent.removeMonitor(monitor)
            globalDismissMonitor = nil
        }
    }

    // MARK: - Fenêtre flottante

    /// Affiche le cockpit dans une fenêtre flottante, sous l'icône — ou sous
    /// le cran quand il vient de l'îlot.
    func showPinnedPanel(anchoredToNotch: Bool = false) {
        cockpitAnchoredToNotch = anchoredToNotch

        if popover.isShown {
            popover.performClose(nil)
        }

        let panel = pinnedPanel ?? makePinnedPanel()
        pinnedPanel = panel
        panel.alphaValue = 1

        if panel.contentView !== cockpitView {
            detachCockpitView()
            panel.contentView = cockpitView
        }
        panel.setContentSize(cockpitView.frame.size)
        cockpitView.needsDisplay = true
        positionPinnedPanel(panel)
        panel.orderFront(nil)
        // Une vue qui vient de changer de fenêtre peut ne pas être dessinée
        // avant le prochain tour de boucle : on force le premier dessin,
        // sinon la fenêtre apparaît vide, avec pour seul décor son ombre.
        cockpitView.displayIfNeeded()
        panel.displayIfNeeded()
        cockpitView.theme.voice.say(cockpitView.theme.copy.randomWhisper())
    }

    /// Détache le cockpit de la fenêtre qui le contient, s'il y en a une.
    func detachCockpitView() {
        if let window = cockpitView.window, window.contentView === cockpitView {
            window.contentView = nil
        } else if cockpitView.superview != nil {
            cockpitView.removeFromSuperview()
        }
    }

    /// Ferme la fenêtre flottante.
    ///
    /// Trois précautions, parce qu'un menu ouvert peut retarder la sortie
    /// d'une fenêtre :
    /// 1. l'alpha tombe à zéro **tout de suite** — même si AppKit diffère
    ///    la fermeture, plus rien n'est visible, ni contenu ni ombre ;
    /// 2. la fenêtre est retirée de l'écran avec son contenu intact ;
    /// 3. le contenu n'est détaché qu'ensuite, une fois la fenêtre cachée.
    func hidePinnedPanel() {
        guard let panel = pinnedPanel else { return }
        pinnedPanel = nil

        panel.alphaValue = 0
        panel.orderOut(nil)
        // La vue resservira au popover : on la lui rend tout de suite.
        popover.contentViewController?.view = cockpitView

        panel.contentView = nil
        panel.close()
    }

    func makePinnedPanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: cockpitView.frame.size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        // Suivre l'utilisateur d'un espace à l'autre et rester visible
        // au-dessus d'une app en plein écran.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    /// Place le panneau sous l'icône, aligné à droite, et le garde dans
    /// l'écran si la barre de menus est proche d'un bord. Un cockpit ouvert
    /// depuis l'îlot reste, lui, accroché sous le cran.
    func positionPinnedPanel(_ panel: NSPanel) {
        if cockpitAnchoredToNotch, let island = notchIsland,
           island.anchorFrame != .zero {
            position(panel, underNotchOf: island)
            return
        }

        guard let button = statusItem?.button, let window = button.window else {
            // Sans icône de barre de menus, le cran reste le seul ancrage.
            if let island = notchIsland, island.anchorFrame != .zero {
                position(panel, underNotchOf: island)
            }
            return
        }
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        let size = panel.frame.size
        let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero

        var origin = NSPoint(x: buttonFrame.maxX - size.width,
                             y: buttonFrame.minY - size.height - 2)
        origin.x = max(visible.minX + 8, min(origin.x, visible.maxX - size.width - 8))
        origin.y = max(visible.minY + 8, origin.y)
        panel.setFrameOrigin(origin)
    }

    /// Centre le panneau sous le bord bas du cran, sans sortir de l'écran.
    func position(_ panel: NSPanel, underNotchOf island: NotchIslandController) {
        let anchor = island.anchorFrame
        let size = panel.frame.size
        let visible = (island.screen ?? NSScreen.main)?.visibleFrame ?? .zero

        var origin = NSPoint(x: anchor.midX - size.width / 2,
                             y: anchor.minY - size.height - 8)
        origin.x = max(visible.minX + 8, min(origin.x, visible.maxX - size.width - 8))
        origin.y = max(visible.minY + 8, origin.y)
        panel.setFrameOrigin(origin)
    }

    /// Tue le processus demandé, après le rituel du theme. Un échec (SIP,
    /// autre utilisateur) est signalé dans les mots du theme courant.
    func killProcess(_ process: ProcessUsage) {
        guard ProcessControl.terminate(process.pid) else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = loc(theme.copy.killFailureTitleKey, process.name)
            alert.informativeText = loc(theme.copy.killFailureBodyKey)
            alert.addButton(withTitle: loc("OK"))
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
            return
        }
        // Rafraîchir manuellement après un kill
        refresh()
    }
}
