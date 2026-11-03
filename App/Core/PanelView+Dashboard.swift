//
//  PanelView+Dashboard.swift
//  HAL
//
//  L'onglet de synthèse : huit métriques en quatre rangées, puis la bande
//  son. Le noyau calcule les valeurs ; le thème les habille et les nomme.
//

import AppKit

extension PanelView {

    /// Locale des majuscules de libellés : `uppercased()` sans argument
    /// utilise la locale système, pas celle choisie dans l'app.
    private static let uiLocale = Locale(identifier: Localization.current)

    // MARK: - Onglet dashboard

    func drawDashboard(at cursorY: inout CGFloat) {
        drawComputeRow(at: &cursorY)
        drawStorageRow(at: &cursorY)
        drawIOAndThermalRow(at: &cursorY)
        drawPowerAndBluetoothRow(at: &cursorY)
        // La bande son ferme la pile : grille de haut-parleur (HAL) ou
        // bibliothèque audio (LCARS), selon le renderer.
        drawAudioBand(at: cursorY)
        cursorY += theme.geometry.speakerBandHeight + gridGap
    }

    // MARK: Rangées d'écrans

    private func screenRect(column: Int, at rowY: CGFloat) -> NSRect {
        NSRect(x: contentX + CGFloat(column) * (screenW + gridGap),
               y: rowY, width: screenW, height: screenH)
    }

    /// CPU et GPU.
    private func drawComputeRow(at cursorY: inout CGFloat) {
        let cpu = snapshot.cpu.total
        // La température vit dans son propre écran, juste en dessous :
        // pas de doublon à côté de la charge.
        drawScreen(rect: screenRect(column: 0, at: cursorY),
                   slot: .cpu,
                   value: String(format: "%.0f %%", cpu),
                   sub: loc("%1$d cores · %2$@", snapshot.cpu.perCore.count,
                            HostInfo.chipString),
                   hot: cpu >= 80,
                   fraction: cpu / 100)

        let gpu = snapshot.gpu
        drawScreen(rect: screenRect(column: 1, at: cursorY),
                   slot: .gpu,
                   value: "\(gpu.deviceUtilization) %",
                   sub: loc("video mem %@", Formatters.bytes(gpu.inUseMemory)),
                   fraction: Double(gpu.deviceUtilization) / 100)
        cursorY += screenH + gridGap
    }

    /// Mémoire et disque.
    private func drawStorageRow(at cursorY: inout CGFloat) {
        let memory = snapshot.memory
        drawScreen(rect: screenRect(column: 0, at: cursorY),
                   slot: .memory,
                   value: "\(Int(memory.fraction * 100)) %",
                   sub: "\(Formatters.bytes(memory.used)) / \(Formatters.bytes(memory.total))",
                   hot: memory.fraction >= 0.8,
                   fraction: memory.fraction)

        let disk = snapshot.disk
        drawScreen(rect: screenRect(column: 1, at: cursorY),
                   slot: .disk,
                   value: disk.isPresent ? "\(Int((disk.fraction * 100).rounded())) %" : "—",
                   sub: disk.isPresent
                       ? loc("read %1$@ · write %2$@",
                             Formatters.rate(disk.readPerSecond),
                             Formatters.rate(disk.writePerSecond))
                       : loc("no data"),
                   fraction: disk.fraction)
        cursorY += screenH + gridGap
    }

    /// Réseau et température SoC.
    private func drawIOAndThermalRow(at cursorY: inout CGFloat) {
        let network = snapshot.network
        let netFraction = NetworkUsage.loadFraction(
            bytesPerSecond: max(network.downloadPerSecond, network.uploadPerSecond))
        drawScreen(rect: screenRect(column: 0, at: cursorY),
                   slot: .network,
                   value: "↓ \(Formatters.rate(network.downloadPerSecond))",
                   sub: "↑ \(Formatters.rate(network.uploadPerSecond))"
                       + (network.activeInterface.map { " · \($0)" } ?? ""),
                   small: true,
                   fraction: netFraction)

        let temperature = snapshot.temperature
        let peak = temperature.socPeak
        drawScreen(rect: screenRect(column: 1, at: cursorY),
                   slot: .temperature,
                   value: peak.map { String(format: "%.1f °C", $0) } ?? "—",
                   sub: temperature.socAverage
                       .map { loc("avg %1$.1f °C · %2$d points", $0, temperature.dieCount) }
                       ?? loc("no sensor"),
                   hot: (peak ?? 0) >= 80,
                   fraction: temperatureFraction)
        cursorY += screenH + gridGap
    }

    /// Batterie et Bluetooth.
    private func drawPowerAndBluetoothRow(at cursorY: inout CGFloat) {
        let battery = snapshot.battery
        // Norme d'Apple : ambre si le Mode économie d'énergie est actif ou
        // si macOS retient la charge au plafond, rouge à 20 % et en dessous,
        // couleur nominale du thème ailleurs. Aucun seuil haut.
        let batteryCritical = battery.isPresent && ThemePalette.isBatteryCritical(battery)
        var batteryValue = battery.isPresent ? "\(battery.level) %" : "—"
        if let minutes = battery.timeRemainingMinutes, minutes > 0, battery.isCharging {
            batteryValue += " ⚡"
        }
        drawScreen(rect: screenRect(column: 0, at: cursorY),
                   slot: .battery,
                   value: batteryValue,
                   sub: Self.batterySubtitle(battery),
                   hot: batteryCritical,
                   fraction: Double(battery.level) / 100,
                   tint: battery.isPresent ? theme.palette.battery(battery) : nil)

        let bluetooth = snapshot.bluetooth
        // Même seuil bas que la batterie, et rien d'autre : le niveau le
        // plus haut des accessoires sert à la barre comme à la couleur, et
        // un plein ne déclenche aucune alarme.
        let btFraction = bluetoothFraction
        let btLevel = Int((btFraction * 100).rounded())
        let btValue: String
        if bluetooth.isEmpty {
            btValue = "—"
        } else {
            btValue = bluetooth.count == 1
                ? loc("%1$d device", bluetooth.count)
                : loc("%1$d devices", bluetooth.count)
        }
        let names = bluetooth.prefix(2).map { $0.name }.joined(separator: ", ")
        drawScreen(rect: screenRect(column: 1, at: cursorY),
                   slot: .bluetooth,
                   value: btValue,
                   sub: bluetooth.isEmpty
                       ? loc("no accessories paired")
                       : Self.bluetoothName(names, truncatedTo: 26),
                   hot: ThemePalette.isBatteryLow(btLevel),
                   small: true,
                   fraction: btFraction,
                   tint: bluetooth.isEmpty ? nil : theme.palette.accessory(btLevel))
        cursorY += screenH + gridGap
    }

    // MARK: - Appel au thème

    /// Prépare le libellé localisé et en majuscules, puis laisse le thème
    /// composer l'écran (bezelle ou bloc, jauge continue ou segments).
    private func drawScreen(rect: NSRect, slot: ScreenSlot, value: String,
                            sub: String, hot: Bool = false, small: Bool = false,
                            fraction: Double, tint: NSColor? = nil) {
        let label = theme.copy.screenLabel(slot).uppercased(with: Self.uiLocale)
        theme.renderer.drawScreen(in: self, spec: ScreenSpec(
            rect: rect, label: label, value: value, sub: sub,
            hot: hot, small: small, fraction: fraction, tint: tint))
    }

    // MARK: - Sous-titres

    private static func batterySubtitle(_ battery: BatteryStatus) -> String {
        guard battery.isPresent else { return loc("desktop mode") }
        // Le plafond choisi dans Réglages > Batterie vaut mieux que le
        // reste à charger : c'est l'état que l'utilisateur a demandé.
        if battery.isAtChargeLimit { return loc("charge limit reached") }
        if let minutes = battery.timeRemainingMinutes, minutes > 0 {
            return battery.isCharging
                ? loc("charging · full in %@", Formatters.duration(minutes))
                : loc("%@ remaining", Formatters.duration(minutes))
        }
        return battery.isCharging ? loc("charging") : loc("on AC power")
    }

    private static func bluetoothName(_ name: String, truncatedTo max: Int) -> String {
        name.count > max ? String(name.prefix(max)) + "…" : name
    }

    private var temperatureFraction: Double {
        guard let peak = snapshot.temperature.socPeak else { return 0 }
        return max(0, min(1, (peak - 30) / 70))
    }

    private var bluetoothFraction: Double {
        guard !snapshot.bluetooth.isEmpty else { return 0 }
        let levels = snapshot.bluetooth.flatMap { $0.components }.map { Double($0.level) }
        return levels.isEmpty ? 0 : (levels.max() ?? 0) / 100
    }

    // MARK: Zones d'extinction finale

    /// Zones des écrans du dashboard, dans l'ordre d'extinction : les
    /// systèmes s'éteignent un à un, du bas vers le haut, et l'en-tête
    /// ferme la marche.
    var dashboardScreenRects: [NSRect] {
        let startY = theme.geometry.dashboardStartY + CGFloat(alertCount) * 30
        let rowStep = screenH + gridGap

        var rects: [NSRect] = []
        // La bande son est sous tout le reste : elle s'éteint la première.
        let band = speakerBandRect(at: startY + rowStep * 4)
        if !band.isEmpty { rects.append(band) }
        for row in stride(from: 3, through: 0, by: -1) {
            let rowY = startY + rowStep * CGFloat(row)
            rects.append(NSRect(x: contentX + screenW + gridGap, y: rowY,
                                width: screenW, height: screenH))
            rects.append(NSRect(x: contentX, y: rowY, width: screenW, height: screenH))
        }
        // L'en-tête s'éteint en tout dernier : l'œil de HAL, l'insigne de
        // la Fédération.
        rects.append(NSRect(x: 0, y: 0, width: bounds.width,
                            height: theme.geometry.headerBottom))
        return rects
    }
}
