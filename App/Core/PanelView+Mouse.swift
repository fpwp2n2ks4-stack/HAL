//
//  PanelView+Mouse.swift
//  HAL
//
//  Les souris du panneau, communes aux thèmes : survol des processus,
//  curseur, onglets, punaise, et la voix du thème quand le curseur entre
//  dans la zone de son œil ou de son insigne.
//

import AppKit

extension PanelView {

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
    }

    /// Le panneau quitte sa fenêtre (popover fermé) : le thème se tait.
    /// Sans cela, sa dernière phrase continuerait après la disparition du
    /// panneau — une voix sans visage.
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        guard newWindow == nil else { return }
        wasOverHeader = false
        theme.voice.hush()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds,
                                      options: [.mouseMoved, .mouseEnteredAndExited,
                                                .activeAlways, .inVisibleRect],
                                      owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let index = processRows.firstIndex { $0.buttonRect.contains(point) }
        if index != hoveredRow {
            hoveredRow = index
            needsDisplay = true
        }

        // La punaise se survole comme un bouton : le curseur le dit.
        let overPin = pinRect.contains(point)
        (processRows.contains { $0.killable && $0.buttonRect.contains(point) } || overPin
            ? NSCursor.pointingHand : NSCursor.arrow).set()

        updateStateToolTip(at: point)
        updatePinToolTip(at: point)
        speakIfOverHeader(point)
    }

    /// La glose d'état TCP, posée sur la ligne survolée.
    ///
    /// La vue porteuse est repositionnée sur la zone d'état et son infobulle
    /// reçoit la glose du thème. Hors survol, elle est masquée.
    private func updateStateToolTip(at point: NSPoint) {
        guard let hit = connectionStateRects.first(where: { $0.rect.contains(point) })
        else {
            stateTipView.isHidden = true
            return
        }
        guard let gloss = theme.copy.gloss(for: hit.state) else {
            stateTipView.isHidden = true
            return
        }
        stateTipView.toolTip = gloss
        stateTipView.frame = hit.rect
        stateTipView.isHidden = false
    }

    /// L'infobulle de la punaise, posée sur son rectangle. Son texte suit
    /// l'état : une punaise déjà plantée propose de la retirer.
    private func updatePinToolTip(at point: NSPoint) {
        guard pinRect.contains(point) else {
            pinTipView.isHidden = true
            return
        }
        pinTipView.toolTip = loc(isPinned
            ? theme.copy.pinOffKey
            : theme.copy.pinOnKey)
        pinTipView.frame = pinRect
        pinTipView.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        if hoveredRow != nil {
            hoveredRow = nil
            needsDisplay = true
        }
        if !stateTipView.isHidden {
            stateTipView.isHidden = true
        }
        pinTipView.isHidden = true
        wasOverHeader = false
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // La punaise passe devant les onglets : elle est à leur droite et
        // rien ne les recouvre.
        if pinRect.contains(point) {
            isPinned.toggle()
            onTogglePin?(isPinned)
            updatePinToolTip(at: point)
            return
        }

        for (entry, rect) in tabRects where rect.contains(point) {
            if tab != entry {
                tab = entry
                theme.voice.say(theme.copy.randomWhisper())
                return
            }
            return
        }

        guard let row = processRows.first(where: { $0.killable && $0.buttonRect.contains(point) })
        else { return }
        performProcessTermination(row.process)
    }

    /// L'œil / l'insigne du panneau parle : quand le curseur entre dans sa
    /// zone, le thème dit à voix haute la réplique de l'infobulle. On ne
    /// parle qu'à l'entrée — pas à chaque pixel parcouru.
    private func speakIfOverHeader(_ point: NSPoint) {
        let overHeader = headerTipView.frame.contains(point)
        guard overHeader != wasOverHeader else { return }
        wasOverHeader = overHeader
        guard overHeader else { return }

        let line = theme.copy.randomWhisper()
        headerTipView.toolTip = line
        theme.voice.say(line)
    }
}
