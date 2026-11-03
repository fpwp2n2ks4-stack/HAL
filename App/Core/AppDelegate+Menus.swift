//
//  AppDelegate+Menus.swift
//  HAL
//
//  La barre de menus et ses menus : statut, clics, contextes, langue,
//  thème, métrique. Séparés du corps principal.
//

import AppKit

extension AppDelegate {

    // MARK: - Barre de menus

    func setupStatusItem() {
        // Un écran à cran porte déjà l'îlot : c'est lui, et lui seul, qui
        // affiche l'identité. On ne crée donc aucune seconde icône dans la
        // barre de menus. Sans cran (écran externe seul), l'item reste le
        // point d'entrée de secours.
        // guard NotchGeometry.preferred()?.hasNotch != true else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        installStatusView()
        item.button?.target = self
        item.button?.action = #selector(handleClick)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    /// Pose la vue du theme courant sur le bouton de la barre de menus.
    /// L'infobulle va sur l'icône, pas sur le bouton : c'est l'icône qui se
    /// trouve sous le curseur, et c'est donc à elle qu'AppKit demande quoi
    /// afficher. Posée sur le bouton, elle ne s'affiche jamais.
    func installStatusView() {
        guard let statusItem else { return }
        statusView?.removeFromSuperview()
        let view = theme.makeStatusItemView(snapshot: latest)
        statusView = view
        view.toolTip = theme.copy.randomWhisper()
        statusItem.button?.addSubview(view)
        view.isHidden = false
        view.needsDisplay = true
        updateStatusItemSize()
    }

    func updateStatusItemSize() {
        guard let statusItem,
              let button = statusItem.button,
              let statusView else { return }
        let size = statusView.intrinsicContentSize
        let inset: CGFloat = 6
        statusItem.length = size.width + inset * 2
        statusView.frame = NSRect(x: inset,
                                  y: (max(button.bounds.height, 22) - size.height) / 2,
                                  width: size.width,
                                  height: size.height)
    }

    @objc func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    @objc func togglePopover() {
        if cockpitIsVisible {
            closeCockpit()
        } else {
            openCockpit()
        }
    }

    func showContextMenu() {
        guard let statusItem else { return }
        let menu = makeContextMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    /// Menu de réglages, partagé par l'icône de la barre de menus et l'îlot
    /// du cran : même contenu, deux chemins d'accès.
    /// Une entrée de sous-menu à coches.
    private struct CheckEntry {
        let label: String
        let value: Any
        let action: Selector
        let isChecked: Bool
    }

    /// Un sous-menu à coches : le même squelette pour le thème, la métrique
    /// et la langue. Seul le contenu change.
    private func checkedSubmenu(title: String, entries: [CheckEntry]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for entry in entries {
            let child = NSMenuItem(title: entry.label,
                                   action: entry.action,
                                   keyEquivalent: "")
            child.target = self
            child.representedObject = entry.value
            child.state = entry.isChecked ? .on : .off
            submenu.addItem(child)
        }
        item.submenu = submenu
        return item
    }

    func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        // L'identité de l'interface : le choix survit au redémarrage et
        // s'applique à chaud, sans relancer l'application.
        menu.addItem(checkedSubmenu(
            title: loc("Theme"),
            entries: themes.available.map { candidate in
                CheckEntry(label: candidate.displayName,
                          value: candidate.id.rawValue,
                          action: #selector(selectTheme(_:)),
                          isChecked: candidate.id == theme.id)
            }))

        // Métrique affichée à côté de l'œil ou de l'insigne : CPU par
        // défaut, mais le thème nomme la sonde à sa façon.
        menu.addItem(checkedSubmenu(
            title: loc(theme.copy.metricMenuKey),
            entries: SystemMetric.allCases.map { metric in
                CheckEntry(label: theme.copy.metricLabel(metric),
                           value: metric.rawValue,
                           action: #selector(selectMetric(_:)),
                           isChecked: metric == SystemMetric.current)
            }))

        // Langue de l'interface.
        menu.addItem(checkedSubmenu(
            title: loc("Language"),
            entries: Localization.supported.map { language in
                CheckEntry(label: language.name,
                           value: language.code,
                           action: #selector(selectLanguage(_:)),
                           isChecked: language.code == Localization.current)
            }))

        // Épinglage : le même réglage que la punaise du panneau, mais là
        // où on le cherche naturellement — dans le menu de l'icône.
        let pinItem = NSMenuItem(title: loc(theme.copy.keepVisibleKey),
                                 action: #selector(togglePinnedFromMenu(_:)),
                                 keyEquivalent: "")
        pinItem.target = self
        pinItem.state = cockpitView.isPinned ? .on : .off
        menu.addItem(pinItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: loc(theme.copy.quitKey),
                                  action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    /// Clic droit sur l'îlot : le menu s'affiche à l'endroit du clic, sans
    /// passer par l'icône de la barre de menus.
    func showNotchContextMenu(_ event: NSEvent) {
        guard let view = notchIsland?.anchorView else { return }
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: view)
    }

    @objc func selectTheme(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let id = ThemeID(rawValue: raw) else { return }
        themes.select(id)
    }

    @objc func selectMetric(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? Int,
              let metric = SystemMetric(rawValue: raw) else { return }
        SystemMetric.current = metric
        statusView?.needsDisplay = true
        updateStatusItemSize()
    }

    @objc func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        Localization.set(code)
        // Le panneau et l'item de barre de menus relisent `loc()` à chaque
        // dessin : un simple rafraîchissement suffit.
        statusView?.needsDisplay = true
        cockpitView?.needsDisplay = true
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    /// Bascule l'épinglage depuis le menu : la fenêtre flottante apparaît
    /// ou disparaît, et le panneau redessine sa punaise en conséquence.
    @objc func togglePinnedFromMenu(_ sender: NSMenuItem) {
        cockpitView.isPinned.toggle()
        applyPin(cockpitView.isPinned)
    }

    /// Bascule d'identité. La notification part pendant que le menu se
    /// referme : on laisse finir le tour de boucle avant de reconstruire
    /// popover et fenêtre flottante, sinon AppKit se bat avec le menu.
    @objc func themeDidChange(_ notification: Notification) {
        Task { @MainActor in
            self.applyTheme()
        }
    }

    /// Reconstruit ce qui dépend du theme sans toucher à ce qui appartient
    /// à la session : dernier relevé, onglet actif, épinglage, visibilité.
    func applyTheme() {
        let wasVisible = cockpitIsVisible
        let pinned = cockpitView?.isPinned ?? false
        let tab = cockpitView?.tab ?? .dashboard

        // Une voix de l'ancien theme ne doit pas finir sa phrase dans le
        // nouveau.
        for candidate in themes.available {
            candidate.voice.hush()
        }

        if popover.isShown {
            popover.performClose(nil)
        }
        if let panel = pinnedPanel {
            panel.alphaValue = 0
            panel.orderOut(nil)
            panel.contentView = nil
            panel.close()
            pinnedPanel = nil
        }

        installStatusView()

        let view = makePanelView()
        view.tab = tab
        view.isPinned = pinned
        cockpitView = view
        popover.contentViewController = makeController(for: view)
        popover.contentSize = view.frame.size

        if wasVisible {
            if pinned {
                showPinnedPanel(anchoredToNotch: cockpitAnchoredToNotch)
            } else {
                openPopover(anchoredTo: cockpitAnchoredToNotch ? notchIsland : nil)
            }
        }

        // L'îlot change de vocabulaire et de palette comme le reste.
        notchIsland?.applyTheme(theme)
    }
}
