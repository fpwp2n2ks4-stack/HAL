//
//  NotchIslandView.swift
//  HAL
//
//  Le dessin de l'îlot. Au repos, aucun fond : seule la marque du thème
//  (l'œil de HAL, l'insigne LCARS…) flotte juste à gauche de la caméra,
//  fondue dans la barre de menus. Déplié, une bande sombre translucide
//  apparaît sous le cran, avec deux lignes de texte et la valeur.
//
//  Le contenu n'apparaît pas d'un coup : son opacité suit la hauteur de la
//  fenêtre. La révélation *est* l'animation, sans second timer ni calque.
//

import AppKit

final class NotchIslandView: NSView {

    // MARK: - État fourni par le contrôleur

    var theme: ThemeDefinition
    var snapshot: Snapshot

    /// Hauteur du cran sur l'écran courant : au repos, la vue ne fait que
    /// cette hauteur et rien d'autre ne s'affiche.
    var notchHeight: CGFloat = 32

    /// Largeur du cran : la marque se place juste à gauche, dans l'aile.
    var notchWidth: CGFloat = 200

    /// Hauteur de la bande d'informations sous le cran.
    let stripHeight: CGFloat = 58

    /// Titre (vocabulaire du thème) et détail (valeur ou message).
    var title: String = ""
    var detail: String = ""
    var tint: NSColor = .white

    /// L'îlot est-il sorti de veille ? Au repos, la seule marque flotte à
    /// hauteur de barre de menus ; déplié, la bande d'informations apparaît
    /// sous le cran.
    var isAwake: Bool = false {
        didSet {
            updateBadgeMode()
            // La marque ne clignote pas : elle reste à côté de la caméra
            // pendant que le texte, lui, se révèle.
            badge.alphaValue = 1
            needsDisplay = true
        }
    }

    var onOpen: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    var onContextMenu: ((NSEvent) -> Void)?

    private(set) var badge: StatusItemView

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }

    // MARK: - Cycle de vie

    init(theme: ThemeDefinition, snapshot: Snapshot) {
        self.theme = theme
        self.snapshot = snapshot
        self.badge = theme.makeStatusItemView(snapshot: snapshot)
        self.tint = theme.palette.accent
        super.init(frame: .zero)
        // Au repos la marque est visible : c'est la seule chose que l'îlot
        // montre quand il dort.
        badge.alphaValue = 1
        addSubview(badge)
        updateBadgeMode()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) n'est pas supporté") }

    /// Le thème change à chaud : la marque est la seule pièce à remplacer.
    func applyTheme(_ newTheme: ThemeDefinition) {
        theme = newTheme
        badge.removeFromSuperview()
        badge = newTheme.makeStatusItemView(snapshot: snapshot)
        badge.alphaValue = 1
        addSubview(badge)
        tint = newTheme.palette.accent
        updateBadgeMode()
        needsDisplay = true
    }

    func setSnapshot(_ newSnapshot: Snapshot) {
        snapshot = newSnapshot
        badge.snapshot = newSnapshot
        needsLayout = true
        needsDisplay = true
    }

    // MARK: - Géométrie

    /// 0 au repos, 1 une fois la bande entièrement sortie. Sert d'opacité
    /// au contenu et de rayon aux coins bas.
    private var reveal: CGFloat {
        guard stripHeight > 0 else { return 0 }
        return max(0, min(1, (bounds.height - notchHeight) / stripHeight))
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        badge.alphaValue = 1
        needsLayout = true
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let size = badge.intrinsicContentSize

        // La marque reste collée au bord gauche du cran, à la même place à
        // l'écran dans les deux états : la fenêtre s'élargit vers la gauche
        // quand elle s'ouvre, donc on mesure depuis le cran, pas depuis le
        // bord de la vue. Deux points suffisent : l'œil doit toucher la
        // caméra, pas flotter au milieu d'une aile noire.
        let notchLeft = max(0, (bounds.width - notchWidth) / 2)
        let gap: CGFloat = 2
        let badgeX = max(0, notchLeft - size.width - gap)

        // Le haut de la fenêtre ne bouge jamais : la marque vit dans la
        // hauteur du cran, y compris pendant l'animation. On la mesure donc
        // depuis le haut courant, jamais depuis la bande de texte.
        let badgeY = bounds.height - (notchHeight + size.height) / 2

        badge.frame = NSRect(x: badgeX,
                             y: badgeY,
                             width: size.width,
                             height: size.height)
    }

    /// La marque reste seule dans l'aile, même dépliée : les valeurs sont
    /// dans la bande de texte, pas à côté de la caméra. Cela garde l'îlot
    /// compact et évite que la marque se décale quand la métrique change de
    /// largeur.
    private func updateBadgeMode() {
        badge.showsReadout = false
        needsLayout = true
    }

    /// Le premier clic doit porter, même si l'application n'est pas active.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Dessin

    /// Attributs d'une phrase du bandeau, coupée au mot près et centrée :
    /// le titre comme le détail peuvent tenir sur deux lignes.
    private func wrappedAttributes(size: CGFloat, alpha: CGFloat, bold: Bool)
        -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let color = bold
            ? tint.withAlphaComponent(alpha)
            : theme.palette.dim.withAlphaComponent(alpha)
        var attributes = theme.type.attributes(size, color: color, bold: bold)
        attributes[.paragraphStyle] = style
        return attributes
    }

    override func draw(_ dirtyRect: NSRect) {
        let revealAmount = reveal

        // === DÉBOGAGE: Fond semi-transparent pour voir la zone du panel === 
        // NSColor.red.withAlphaComponent(0.1).setFill()
        // NSRectFill(bounds)

        // Au repos, aucun fond : la marque flotte seule dans la barre de
        // menus. Le noir n'apparaît qu'avec la bande d'informations et
        // s'efface au rythme de sa rétractation, sans laisser de carré
        // opaque autour de l'œil.

        // === NOUVEAU: Toujours dessiner les métriques permanentes === 
        // Même quand l'îlot est fermé
        drawPermanentMetrics()

        // Si reveal est significatif, on dessine aussi le fond et le contenu
        guard revealAmount > 0.01 else {
            return
        }

        let corner = 12 + 4 * revealAmount

        NSColor.black.withAlphaComponent(min(1, revealAmount * 1.4)).setFill()
        shape(cornerRadius: corner).fill()

        // Contenu classique (œil, texte, etc.)
        drawContent(reveal: revealAmount)

        // Redessiner les métriques par-dessus le fond noir
        drawPermanentMetrics()

        // Liseré : il souligne le bas de la bande d'informations.
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 0, y: 0.75))
        line.line(to: NSPoint(x: bounds.width, y: 0.75))
        tint.withAlphaComponent(0.35 * revealAmount).setStroke()
        line.lineWidth = 1.5
        line.stroke()

        guard isAwake else { return }

        // Barre d'état verticale, à droite : la couleur dit la gravité.
        let barHeight: CGFloat = 18
        let bar = NSBezierPath(roundedRect: NSRect(x: bounds.width - 14,
                                                  y: (stripHeight - barHeight) / 2,
                                                  width: 2.5,
                                                  height: barHeight),
                               xRadius: 1.25, yRadius: 1.25)
        tint.withAlphaComponent(0.85 * revealAmount).setFill()
        bar.fill()

        drawContent(reveal: revealAmount)
    }

    /// Forme de l'îlot : bords hauts confondus avec le bord de l'écran,
    /// coins bas arrondis. Les courbes sont cubiques, avec les deux points
    /// de contrôle dans le coin — l'équivalent exact d'une quadratique.
    private func shape(cornerRadius radius: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        let minX = bounds.minX, maxX = bounds.maxX
        let minY = bounds.minY, maxY = bounds.maxY
        let radius = min(radius, min(bounds.width / 2, bounds.height))

        path.move(to: NSPoint(x: minX, y: maxY))
        path.line(to: NSPoint(x: maxX, y: maxY))
        path.line(to: NSPoint(x: maxX, y: minY + radius))
        path.curve(to: NSPoint(x: maxX - radius, y: minY),
                   controlPoint1: NSPoint(x: maxX, y: minY),
                   controlPoint2: NSPoint(x: maxX, y: minY))
        path.line(to: NSPoint(x: minX + radius, y: minY))
        path.curve(to: NSPoint(x: minX, y: minY + radius),
                   controlPoint1: NSPoint(x: minX, y: minY),
                   controlPoint2: NSPoint(x: minX, y: minY))
        path.close()
        return path
    }

    private func drawContent(reveal amount: CGFloat) {
        guard isAwake else { return }

        let textX: CGFloat = 26
        let textWidth = max(0, bounds.width - textX * 2)

        let titleAttributes = wrappedAttributes(size: 10, alpha: amount, bold: true)
        let detailAttributes = wrappedAttributes(size: 9, alpha: amount, bold: false)

        let titleFont = theme.type.font(10, bold: true)
        let detailFont = theme.type.font(9)
        let titleLineHeight = ceil(titleFont.ascender
                                   - titleFont.descender
                                   + titleFont.leading) + 1
        let detailLineHeight = ceil(detailFont.ascender
                                    - detailFont.descender
                                    + detailFont.leading) + 1

        // Les deux blocs sont empilés depuis le haut de la bande. Le titre
        // garde sa position d'origine ; le détail se replace sous lui,
        // quelle que soit la hauteur réellement occupée.
        let contentTop = stripHeight - 4
        let titleHeight = min(textHeight(title, attributes: titleAttributes,
                                         width: textWidth),
                              titleLineHeight * 2 + 2)
        let titleRect = NSRect(x: textX,
                               y: contentTop - titleHeight,
                               width: textWidth,
                               height: titleHeight)

        let detailTop = titleRect.minY - 1
        let detailHeight = min(textHeight(detail, attributes: detailAttributes,
                                          width: textWidth),
                               detailLineHeight * 2 + 2)
        let detailRect = NSRect(x: textX,
                                y: detailTop - detailHeight,
                                width: textWidth,
                                height: detailHeight)

        (title as NSString).draw(
            with: titleRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            attributes: titleAttributes
        )
        (detail as NSString).draw(
            with: detailRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            attributes: detailAttributes
        )
    }

    /// Dessine les métriques en permanence À L'INTÉRIEUR de l'encoche noire du Mac
    private func drawPermanentMetrics() {
        // Calcul des positions À L'INTÉRIEUR du notch
        let notchLeft = max(0, (bounds.width - notchWidth) / 2)
        let notchRight = min(bounds.width, notchLeft + notchWidth)
        let notchCenter = notchLeft + notchWidth / 2

        // Couleur du texte (blanc avec une légère opacité pour être discret)
        let textColor = NSColor.white.withAlphaComponent(0.9)
        let font = NSFont.systemFont(ofSize: 10, weight: .medium)

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: font
        ]

        // === CÔTÉ GAUCHE DE L'ENCOCHE : %CPU + Température ===
        let cpuPercent = Int(snapshot.cpu.total.rounded())
        let tempText = snapshot.temperature.socPeak.map { String(format: "%.0f°C", $0) } ?? "—"
        let leftText = "\(cpuPercent)% · \(tempText)"

        // Position à gauche À L'INTÉRIEUR du notch
        let leftX = notchLeft + 8
        let leftY = bounds.height - notchHeight / 2 - 6
        let leftMaxWidth = notchCenter - leftX - 8
        let leftRect = NSRect(x: leftX, y: leftY, width: leftMaxWidth, height: 14)

        (leftText as NSString).draw(
            with: leftRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            attributes: attributes
        )

        // === CÔTÉ DROIT DE L'ENCOCHE : %GPU + %Mémoire ===
        let gpuPercent = snapshot.gpu.deviceUtilization
        let memPercent = Int((snapshot.memory.fraction * 100).rounded())
        let rightText = "GPU \(gpuPercent)% · MEM \(memPercent)%"

        // Position à droite À L'INTÉRIEUR du notch
        let rightX = notchCenter + 8
        let rightY = bounds.height - notchHeight / 2 - 6
        let rightMaxWidth = notchRight - rightX - 8
        let rightRect = NSRect(x: rightX, y: rightY, width: rightMaxWidth, height: 14)

        (rightText as NSString).draw(
            with: rightRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            attributes: attributes
        )
    }

    /// Hauteur d'un texte replié dans la largeur donnée, arrondie au point
    /// supérieur. Sert à empiler le titre et le détail sans laisser de vide
    /// quand une phrase tient sur une seule ligne.
    private func textHeight(_ text: String,
                            attributes: [NSAttributedString.Key: Any],
                            width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        let bounds = (text as NSString).boundingRect(
            with: NSSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        return ceil(bounds.height)
    }

    // MARK: - Souris

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        onHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHover?(false)
    }

    override func mouseDown(with event: NSEvent) {
        // Contrôle-clic : sur un trackpad, c'est le geste habituel du clic
        // droit. Il doit ouvrir le menu, pas le cockpit.
        if event.modifierFlags.contains(.control) {
            onContextMenu?(event)
            return
        }
        onOpen?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onContextMenu?(event)
    }
}
