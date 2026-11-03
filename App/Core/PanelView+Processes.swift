//
//  PanelView+Processes.swift
//  HAL
//
//  L'onglet des processus : les dix plus gourmands et, sur chacun, le
//  bouton du thème. Le rituel diffère — HAL refuse, LCARS demande une
//  autorisation — mais la mécanique est la même : un délai, puis le
//  processus est terminé.
//

import AppKit

extension PanelView {

    func drawProcessesTab(at cursorY: inout CGFloat) {
        drawProcessesQuote(at: cursorY)
        cursorY += 22

        processRows.removeAll()
        for (index, process) in snapshot.processes.prefix(Self.processRowCount).enumerated() {
            drawProcessRow(process, index: index, at: cursorY)
            cursorY += Self.processRowHeight
        }

        cursorY += 8
        drawProcessesFooter(at: cursorY)
    }

    // MARK: - Divers

    /// Réplique d'ouverture de l'onglet, dans la couleur d'accent du thème.
    private func drawProcessesQuote(at rowY: CGFloat) {
        let attrs = theme.type.attributes(11, color: theme.palette.quote,
                                          bold: true, glow: true)
        theme.copy.processQuote.draw(at: NSPoint(x: contentX, y: rowY),
                                     withAttributes: attrs)
    }

    private func drawProcessesFooter(at rowY: CGFloat) {
        if let key = theme.copy.processFooterKey {
            loc(key).draw(at: NSPoint(x: contentX, y: rowY),
                          withAttributes: theme.type.attributes(
                            8, color: theme.palette.dim))
        }

        // Plaque signalétique, vissée sous l'œil ou gravée sur la console.
        theme.copy.processPlaque.draw(
            at: NSPoint(x: contentX, y: rowY + 12),
            withAttributes: theme.type.attributes(
                7, color: theme.palette.dim.withAlphaComponent(0.7)))
    }

    // MARK: - Une ligne de processus

    private func drawProcessRow(_ process: ProcessUsage, index: Int, at rowY: CGFloat) {
        let isFlat = theme.id.isFlat
        let nameFont = theme.type.font(10, bold: isFlat)
        let valueFont = theme.type.font(10)

        let rowRect = NSRect(x: contentX - 6, y: rowY - 3,
                             width: contentW + 12,
                             height: Self.processRowHeight)
        let buttonAttrs = theme.type.attributes(8, color: theme.palette.danger,
                                                bold: true)
        let buttonWidth = theme.copy.processButton.size(withAttributes: buttonAttrs).width + 14
        let buttonRect = NSRect(x: bounds.width - padding - 10 - buttonWidth,
                                y: rowY - 1,
                                width: buttonWidth,
                                height: 17)
        let row = ProcessRow(process: process, rowRect: rowRect, buttonRect: buttonRect,
                             killable: ProcessControl.canTerminate(process.pid))
        processRows.append(row)

        // Nom, PID, charge.
        let name = truncated(process.name, toWidth: 170, font: nameFont)
        name.draw(at: NSPoint(x: contentX, y: rowY),
                  withAttributes: [.font: nameFont,
                                   .foregroundColor: isFlat ? theme.palette.text : theme.palette.glass])
        let pid = "\(process.pid)"
        pid.draw(at: NSPoint(x: contentX + 178, y: rowY),
                 withAttributes: [.font: valueFont, .foregroundColor: isFlat ? theme.palette.text : theme.palette.dim])

        let cpu = String(format: "%.1f %%", process.cpu)
        drawRight(cpu, at: rowY, rightEdge: buttonRect.minX - 10, font: valueFont,
                  color: process.cpu > 100
                      ? theme.palette.danger
                      : (isFlat ? theme.palette.text : theme.palette.accentSoft))

        // L'action passe en dernier : le rituel du thème peut recouvrir la
        // valeur CPU (LCARS) ou simplement encadrer le bouton (HAL).
        let pending = pendingReplies[process.pid].map {
            (text: theme.copy.processPending, since: $0)
        }
        theme.renderer.drawProcessAction(in: self, spec: ProcessActionSpec(
            rowRect: rowRect, buttonRect: buttonRect,
            title: theme.copy.processButton,
            enabled: row.killable,
            hovered: hoveredRow == index,
            pending: pending))
    }
}
