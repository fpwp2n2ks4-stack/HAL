//
//  NotchIslandController+States.swift
//  HAL
//
//  Les états de l'îlot du cran : réveil, veille, repli. Séparés du corps
//  principal.
//

import AppKit

@MainActor

extension NotchIslandController {

    // MARK: - États

    func handleHover(_ inside: Bool) {
        mouseInside = inside

        if inside {
            collapseTask?.cancel()

            if state == .dormant {
                view.title = theme.copy.randomWhisper()
                view.detail = metricsLine()
                view.tint = theme.palette.accent
                reveal(.hover)
            }
        } else if state != .dormant {
            // Une alerte laissée ouverte par un survol ne doit pas rester
            // indéfiniment : la sortie de souris la referme comme un aperçu.
            scheduleCollapse(after: 0.6)
        }
    }

    func handleClick() {
        guard state != .dormant else { return }
        collapse(animated: true)
        onOpenCockpit()
    }

    func reveal(_ newState: State) {
        guard let geometry else { return }

        collapseTask?.cancel()
        state = newState
        view.isAwake = true
        view.needsDisplay = true
        view.needsLayout = true

        let target = geometry.openFrame(width: openWidth,
                                        contentHeight: view.stripHeight)
        animate(to: target, duration: 0.26) { 1 - pow(1 - $0, 4) }

        if newState == .peek {
            scheduleCollapse(after: 4.5)
        }
    }

    func collapse(animated: Bool) {
        guard let geometry else { return }

        collapseTask?.cancel()
        state = .dormant
        view.needsDisplay = true

        let target = geometry.closedFrame
        if animated {
            // Le contenu s'efface au rythme de la hauteur : `isAwake` ne
            // retombe qu'une fois la fenêtre refermée.
            animate(to: target, duration: 0.22) { $0 * $0 }
        } else {
            cancelAnimation()
            view.isAwake = false
            panel.setFrame(target, display: true)
        }
    }

    /// Animation asynchrone avec Task au lieu de Timer
    func animate(to frame: NSRect,
                 duration: TimeInterval,
                 curve: @escaping (Double) -> Double) {
        animationTask?.cancel()

        animationTask = Task { [weak self] in
            guard let self = self else { return }

            let startFrame = self.panel.frame
            let startTime = Date()
            let totalDuration = max(0.001, duration)

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                let elapsed = Date().timeIntervalSince(startTime)
                let linear = min(1.0, elapsed / totalDuration)
                let eased = curve(linear)

                let currentFrame = NSRect(
                    x: startFrame.minX + (frame.minX - startFrame.minX) * eased,
                    y: startFrame.minY + (frame.minY - startFrame.minY) * eased,
                    width: startFrame.width + (frame.width - startFrame.width) * eased,
                    height: startFrame.height + (frame.height - startFrame.height) * eased
                )

                self.panel.setFrame(currentFrame, display: true)
                self.view.needsDisplay = true

                if linear >= 1.0 {
                    if self.state == .dormant {
                        self.view.isAwake = false
                        self.view.needsDisplay = true
                    }
                    break
                }

                // Attendre le prochain frame (~120 FPS)
                try await Task.sleep(nanoseconds: 8_333_333) // ~1/120 seconde
            }
        }
    }

    func cancelAnimation() {
        animationTask?.cancel()
        animationTask = nil
    }

    /// Planifie la fermeture avec Task au lieu de DispatchQueue
    func scheduleCollapse(after delay: TimeInterval) {
        collapseTask?.cancel()
        guard !mouseInside else { return }

        collapseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self?.collapse(animated: true)
        }
    }

}
