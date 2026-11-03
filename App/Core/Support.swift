//
//  Support.swift
//  HAL
//
//  Formatage, informations machine et métrique de barre de menus : tout ce
//  qui est commun aux thèmes et ne doit surtout pas être dupliqué.
//
//  Les unités sont localisées ; les répliques cultes, elles, restent en
//  anglais — voir `ThemeCopy`.
//

import AppKit

enum Formatters {
    /// Octets en unités lisibles, base 1024. Les unités passent par `loc()` :
    /// « o », « Ko », « Mo » en français, « B », « KB », « MB » sinon.
    static func bytes(_ value: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var amount = value
        var unit = 0
        while amount >= 1024, unit < units.count - 1 {
            amount /= 1024
            unit += 1
        }
        return unit == 0
            ? String(format: "%.0f %@", amount, loc(units[unit]))
            : String(format: "%.1f %@", amount, loc(units[unit]))
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        bytes(bytesPerSecond) + "/s"
    }

    /// Durée en minutes : autonomie restante, temps de charge.
    static func duration(_ minutes: Int) -> String {
        if minutes < 60 { return loc("%d min", minutes) }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? loc("%d h", hours) : loc("%1$d h %2$d", hours, rest)
    }
}

// MARK: - Métrique affichée à côté de l'état

/// La sonde dont la valeur accompagne l'état dans la barre de menus.
///
/// Une seule mécanique pour les deux thèmes — l'ancien `ShipMetric` de
/// Starfleet était un doublon fonctionnel de `EyeMetric`. Le thème ne
/// change que le **nom** de la sonde ; la formule et l'unité sont communes.
enum SystemMetric: Int, CaseIterable {
    case cpu
    case gpu
    case memory
    case network
    case disk
    case temperature
    case battery

    private static let defaultsKey = "systemMetric"

    /// Sonde active : CPU par défaut.
    static var current: SystemMetric {
        get { SystemMetric(rawValue: UserDefaults.standard.integer(forKey: defaultsKey)) ?? .cpu }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    /// Charge de la métrique, en fraction 0...1.
    ///
    /// Mêmes formules que les jauges du panneau : une source dupliquée
    /// divergerait, et l'état de la barre de menus mentirait alors au
    /// tableau de bord.
    func fraction(_ snapshot: Snapshot) -> Double {
        switch self {
        case .cpu:
            return snapshot.cpu.total / 100
        case .gpu:
            return Double(snapshot.gpu.deviceUtilization) / 100
        case .memory:
            return snapshot.memory.fraction
        case .network:
            let peak = max(snapshot.network.downloadPerSecond,
                           snapshot.network.uploadPerSecond)
            return NetworkUsage.loadFraction(bytesPerSecond: peak)
        case .disk:
            return snapshot.disk.fraction
        case .temperature:
            guard let peak = snapshot.temperature.socPeak else { return 0 }
            return max(0, min(1, (peak - 30) / 70))
        case .battery:
            return Double(snapshot.battery.level) / 100
        }
    }

    /// Texte affiché à côté de l'état, dans l'unité propre à la métrique.
    /// Un pourcentage n'a aucun sens pour une température : on affiche les
    /// degrés réels, identiques à ceux du panneau. Le CPU est accompagné de
    /// sa température, lue sur le même capteur que l'écran thermique.
    func readout(_ snapshot: Snapshot) -> String {
        switch self {
        case .temperature:
            guard let peak = snapshot.temperature.socPeak else { return "—" }
            return String(format: "%.0f°C", peak)
        case .cpu:
            let percent = "\(Int((fraction(snapshot) * 100).rounded()))%"
            guard let peak = snapshot.temperature.socPeak else { return percent }
            return String(format: "%@ · %.0f°C", percent, peak)
        default:
            return "\(Int((fraction(snapshot) * 100).rounded()))%"
        }
    }

    /// La couleur d'alarme signifie le contraire pour la batterie : c'est
    /// la réserve qui compte, pas la charge. Le barème est celui du thème,
    /// donc de l'écran : l'état de la barre de menus ne doit jamais
    /// signaler ce que le panneau ne signale pas, ni rester muet quand il
    /// hurle — y compris pour le Mode économie d'énergie, que seul un
    /// `Snapshot` permet de connaître.
    func isCritical(_ snapshot: Snapshot) -> Bool {
        guard self != .battery else {
            let battery = snapshot.battery
            return battery.isPresent && ThemePalette.isBatteryCritical(battery)
        }
        return fraction(snapshot) > 0.80
    }
}

// MARK: - Informations machine

enum HostInfo {
    /// Identifiant de modèle (`Mac17,3` → `MAC 17.3`), condensé pour
    /// l'en-tête du panneau. La variante `MAC - 17.3` de HAL a été
    /// abandonnée : un seul séparateur, lisible dans les deux thèmes.
    static let modelString: String = {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "MAC" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buffer, &size, nil, 0)
        let raw = String(cString: buffer)
        guard let start = raw.range(of: #"\d"#, options: .regularExpression)?.lowerBound else {
            return raw
        }
        let number = raw[start...]
            .replacingOccurrences(of: ",", with: ".")
            .uppercased()
        return "MAC \(number)"
    }()

    static let chipString: String = {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        if size > 0 {
            var buffer = [CChar](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
            let value = String(cString: buffer).trimmingCharacters(in: .whitespaces)
            if !value.isEmpty { return value }
        }
        return "Apple Silicon"
    }()

    /// Nom du vaisseau : le nom de la machine, en majuscules. Chaque Mac
    /// est son propre navire.
    static let shipName: String = {
        let raw = ProcessInfo.processInfo.hostName
        let base = raw.split(separator: ".").first.map(String.init) ?? raw
        let pretty = base.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .uppercased()
        return pretty.isEmpty ? "ENTERPRISE" : pretty
    }()

    /// Numéro d'immatriculation, stable d'un lancement à l'autre.
    static let registry: String = {
        var hash: UInt32 = 2_166_136_261
        for byte in shipName.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        let number = 1701 + Int(hash % 7900)
        return "NCC-\(number)"
    }()
}

/// Date stellaire décorative : 47000.0 au 1er janvier 2026, mille unités
/// par an — la cadence de la série. Elle avance avec l'horloge.
enum Stardate {
    private static let anchor: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }()

    static func string(for date: Date) -> String {
        let days = date.timeIntervalSince(anchor) / 86_400
        let value = 47_000 + days / 365.25 * 1_000
        return String(format: "%.1f", value)
    }
}

enum Interval {
    @MainActor static var current: Double = 2.0
}
