//
//  PanelView+Connections.swift
//  HAL
//
//  L'onglet des connexions : deux zones, entrantes et sortantes. Qui parle
//  à qui, et dans quel état.
//
//  La source est `lsof` (voir `ConnectionReader`, Sensors/Sensors.swift) :
//  elle ne montre que les connexions de l'utilisateur courant, et le pied
//  de l'onglet le dit. Afficher une totalité qu'on n'obtiendrait qu'en
//  réclamant des privilèges serait mentir sur ce qu'on voit réellement.
//

import AppKit

extension PanelView {

    // MARK: - Onglet

    func drawConnectionsTab(at cursorY: inout CGFloat) {
        // Les zones d'état sont remises à zéro à chaque dessin : la liste
        // suit le contenu affiché, pas le contenu précédent.
        connectionStateRects.removeAll()

        drawConnectionsQuote(at: cursorY)
        cursorY += 22

        drawConnectionsSection(
            title: loc("INCOMING"),
            connections: snapshot.connections.filter {
                !$0.isListening && !$0.isDetached && $0.isIncoming
            },
            at: &cursorY
        )
        drawConnectionsSection(
            title: loc("OUTGOING"),
            connections: snapshot.connections.filter {
                !$0.isListening && !$0.isDetached && !$0.isIncoming
            },
            at: &cursorY
        )

        cursorY += 4
        drawConnectionsFooter(at: cursorY)
    }

    // MARK: - Réplique et pied

    private func drawConnectionsQuote(at rowY: CGFloat) {
        let isFlat = theme.id.isFlat
        theme.copy.connectionQuote.draw(
            at: NSPoint(x: contentX, y: rowY),
            withAttributes: theme.type.attributes(
                11, color: isFlat ? theme.palette.text : theme.palette.quote, bold: true, glow: !isFlat))
    }

    /// Le pied dit ce que l'onglet ne peut pas montrer. Sans cette note, un
    /// relevé partiel passerait pour un relevé complet.
    private func drawConnectionsFooter(at rowY: CGFloat) {
        let isFlat = theme.id.isFlat
        let listening = snapshot.connections.filter(\.isListening).count
        let line = listening > 0
            ? (listening == 1
                ? loc("1 listening port · current user only")
                : loc("%1$d listening ports · current user only", listening))
            : loc("current user only")
        line.draw(at: NSPoint(x: contentX, y: rowY),
                  withAttributes: theme.type.attributes(8, color: isFlat ? theme.palette.text : theme.palette.dim))

        // La glose du thème, dans le gris le plus pâle : on la lit en
        // dernier, quand on a déjà eu les chiffres.
        theme.copy.connectionFooterQuote.draw(
            at: NSPoint(x: contentX, y: rowY + 11),
            withAttributes: theme.type.attributes(
                8, color: isFlat ? theme.palette.text : theme.palette.dim.withAlphaComponent(0.55), bold: true))

        theme.copy.connectionPlaque.draw(
            at: NSPoint(x: contentX, y: rowY + 23),
            withAttributes: theme.type.attributes(
                7, color: isFlat ? theme.palette.text : theme.palette.dim.withAlphaComponent(0.7)))
    }

    // MARK: - Une zone

    /// Largeurs des colonnes, calculées une fois pour que l'en-tête et les
    /// lignes s'alignent : la colonne du processus, puis celle de l'état.
    private static var connectionColumns: (process: CGFloat, state: CGFloat) {
        (process: 130, state: 76)
    }

    /// Une zone : titre, puis ses lignes — ou une note discrète quand il n'y
    /// a rien, jamais une zone vide sans explication.
    private func drawConnectionsSection(title: String, connections: [NetworkConnection],
                                        at cursorY: inout CGFloat) {
        drawConnectionsSectionTitle(title, count: connections.count, at: cursorY)
        cursorY += 18

        let shown = connections.prefix(Self.connectionRowCount)
        if shown.isEmpty {
            let isFlat = theme.id.isFlat
            loc("no connection").draw(
                at: NSPoint(x: contentX + 10, y: cursorY),
                withAttributes: theme.type.attributes(
                    9, color: isFlat ? theme.palette.text : theme.palette.dim.withAlphaComponent(0.6)))
            cursorY += Self.connectionRowHeight
        } else {
            for connection in shown {
                drawConnectionRow(connection, at: cursorY)
                cursorY += Self.connectionRowHeight
            }
            let hidden = connections.count - shown.count
            if hidden > 0 {
                let isFlat = theme.id.isFlat
                let note = loc("+%d more", hidden)
                note.draw(at: NSPoint(x: contentX + 10, y: cursorY),
                          withAttributes: theme.type.attributes(
                            8, color: isFlat ? theme.palette.text : theme.palette.dim.withAlphaComponent(0.7)))
                cursorY += Self.connectionRowHeight - 4
            }
        }
        cursorY += 10
    }

    /// En-tête de zone : « INCOMING · 3 », un filet, et l'effectif.
    private func drawConnectionsSectionTitle(_ title: String, count: Int, at rowY: CGFloat) {
        let isFlat = theme.id.isFlat
        let text = "\(title) · \(count)"
        let attrs = theme.type.attributes(10, color: isFlat ? theme.palette.text : theme.palette.accentSoft, bold: true)
        text.draw(at: NSPoint(x: contentX, y: rowY), withAttributes: attrs)

        let width = text.size(withAttributes: attrs).width
        let lineY = rowY + 8
        (isFlat ? theme.palette.text : theme.palette.accentSoft).withAlphaComponent(isFlat ? 0.6 : 0.3).setStroke()
        let rule = NSBezierPath()
        rule.move(to: NSPoint(x: contentX + width + 10, y: lineY))
        rule.line(to: NSPoint(x: bounds.width - padding, y: lineY))
        rule.lineWidth = 1
        rule.stroke()
    }

    // MARK: - Une ligne de connexion

    /// « PROCESSUS · DISTANT · ÉTAT » : de gauche à droite, qui parle, à
    /// qui, et dans quel état. En dessous, en gris, l'adresse locale.
    private func drawConnectionRow(_ connection: NetworkConnection, at rowY: CGFloat) {
        let isFlat = theme.id.isFlat
        let nameFont = theme.type.font(9.5, bold: isFlat)
        let detailFont = theme.type.font(8)
        let columns = Self.connectionColumns

        let name = truncated(connection.process, toWidth: columns.process, font: nameFont)
        name.draw(at: NSPoint(x: contentX, y: rowY),
                  withAttributes: [.font: nameFont,
                                   .foregroundColor: isFlat ? theme.palette.text : theme.palette.glass])

        let valueX = contentX + columns.process
        let stateX = bounds.width - padding - columns.state

        // Le sens se lit sans lire le titre de la zone.
        let arrow = connection.isIncoming ? "←" : "→"
        let remoteText = truncated("\(arrow) \(connection.remote)",
                                   toWidth: stateX - valueX - 8, font: nameFont)
        remoteText.draw(at: NSPoint(x: valueX, y: rowY),
                        withAttributes: [.font: nameFont,
                                         .foregroundColor: isFlat ? theme.palette.text : theme.palette.linkActive])

        let stateAttrs: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: isFlat ? theme.palette.text : Self.connectionStateColor(connection.state, theme: theme)
        ]
        connection.state.draw(at: NSPoint(x: stateX, y: rowY + 1),
                              withAttributes: stateAttrs)

        // La zone d'état est survolable : au survol, le thème y glisse sa
        // glose. La zone mémorisée est un peu plus large que le texte.
        if !connection.state.isEmpty {
            let stateWidth = connection.state.size(withAttributes: stateAttrs).width
            let tipRect = NSRect(x: stateX - 3, y: rowY - 2,
                                 width: stateWidth + 6, height: 16)
            connectionStateRects.append((rect: tipRect, state: connection.state))
        }

        // Ligne secondaire : l'adresse locale, dans un gris qui la met au
        // second plan sous son processus.
        truncated(connection.local, toWidth: stateX - contentX - 8, font: detailFont)
            .draw(at: NSPoint(x: contentX + 10, y: rowY + 10),
                  withAttributes: [.font: detailFont,
                                   .foregroundColor: isFlat
                                       ? theme.palette.text
                                       : theme.palette.dim.withAlphaComponent(0.8)])
    }

    /// Couleur d'un état TCP, dans les teintes du thème.
    private static func connectionStateColor(_ state: String,
                                             theme: ThemeDefinition) -> NSColor {
        switch state {
        case "ESTABLISHED": return theme.palette.linkActive
        case "LISTEN", "": return theme.palette.linkIdle
        default: return theme.palette.linkPending
        }
    }
}
