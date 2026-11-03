//
//  BluetoothReader.swift
//  HAL
//
//  Lecteur des niveaux de charge des accessoires Bluetooth. Récupéré de
//  l'ancien `Sensors/Sensors.swift`, adapté à l'architecture modulaire.
//

import Foundation

/// Niveaux de charge des accessoires Bluetooth (AirPods, souris, casques…).
///
/// ## Pourquoi `pmset`, et pas CoreBluetooth
///
/// Ces valeurs ne sont **pas** dans `IOPSCopyPowerSourcesInfo` : mesuré sur
/// cette machine, il ne renvoie que la batterie interne. CoreBluetooth, lui,
/// exige une autorisation TCC (`NSBluetoothAlwaysUsageDescription`) et un
/// balayage actif ; Toasty n'a ni l'un ni l'autre.
///
/// `pmset -g accps -xml` est le même service que celui qui alimente
/// l'indicateur de batterie des accessoires dans la barre de menus de macOS.
/// Il est bon marché (~15 ms) et ne demande aucun privilège. On le met en
/// cache : les niveaux des accessoires bougent lentement, inutile de lancer
/// un sous-processus toutes les 2 s.
///
/// Limite assumée : seuls les accessoires dont macOS connaît la batterie
/// apparaissent. Un périphérique sans niveau exposé est simplement absent.
public final class BluetoothReader: @unchecked Sendable {
    private var cached: (date: Date, devices: [BluetoothDevice])?
    private let timeToLive: TimeInterval = 20

    public init() {}

    public func read() -> [BluetoothDevice] {
        if let cached, Date().timeIntervalSince(cached.date) < timeToLive {
            return cached.devices
        }
        let devices = Self.collect()
        cached = (Date(), devices)
        return devices
    }

    private static func collect() -> [BluetoothDevice] {
        guard let output = accessoryPowerSources() else { return [] }

        var groups: [String: [[String: Any]]] = [:]
        var standalone: [[String: Any]] = []
        for entry in powerSourcePlistEntries(output) {
            // Le bloc « batterie interne » n'est pas un accessoire : il est
            // déjà lu par `BatteryReader`. Seuls les accessoires nous
            // intéressent.
            guard entry["Type"] as? String == "Accessory Source" else { continue }
            if let group = entry["Group Identifier"] as? String {
                groups[group, default: []].append(entry)
            } else {
                standalone.append(entry)
            }
        }

        var devices = standalone.compactMap(device(from:))
        for entries in groups.values {
            if let device = device(fromGroup: entries) { devices.append(device) }
        }
        return devices.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Périphérique dont les niveaux tiennent en une seule entrée.
    private static func device(from entry: [String: Any]) -> BluetoothDevice? {
        guard let name = entry["Name"] as? String else { return nil }
        let kind = (entry["Part Identifier"] as? String)?.lowercased() ?? "battery"
        guard let component = component(from: entry, kind: kind) else { return nil }
        return BluetoothDevice(name: name, components: [component])
    }

    /// Périphérique décrit par plusieurs entrées partageant un
    /// `Group Identifier` : un casque expose ses deux oreillettes (et son
    /// boîtier) comme autant de sources séparées.
    private static func device(fromGroup entries: [[String: Any]]) -> BluetoothDevice? {
        let combined = entries.first { $0["Part Identifier"] as? String == "Combined" }
        let caseEntry = entries.first { $0["Part Identifier"] as? String == "Case" }
        // `Combined` porte le nom « propre » ; le boîtier s'appelle par
        // exemple « Boîtier AirPods de Yves ».
        let name = combined?["Name"] as? String
            ?? entries.first { $0["Part Identifier"] as? String != "Case" }?["Name"] as? String
            ?? entries.first?["Name"] as? String
            ?? ""

        var components: [BluetoothComponent] = []
        for part in combined?["Combined Parts"] as? [[String: Any]] ?? [] {
            guard let kind = (part["Part Identifier"] as? String)?.lowercased(),
                  let component = component(from: part, kind: kind)
            else { continue }
            components.append(component)
        }
        if let caseEntry, let component = component(from: caseEntry, kind: "case") {
            components.append(component)
        }
        if components.isEmpty,
           let single = combined ?? entries.first,
           let component = component(from: single, kind: "battery") {
            components.append(component)
        }

        guard !components.isEmpty else { return nil }
        return BluetoothDevice(name: name, components: components)
    }

    private static func component(from entry: [String: Any], kind: String) -> BluetoothComponent? {
        guard let level = (entry["Current Capacity"] as? NSNumber)?.intValue else { return nil }
        let charging = entry["Is Charging"] as? Bool ?? false
        return BluetoothComponent(kind: kind, level: level, isCharging: charging)
    }

    /// Décode la sortie de `pmset -g accps -xml`.
    ///
    /// `pmset` imprime **plusieurs** plists à la suite, un par source
    /// d'alimentation, chacun précédé de sa déclaration `<?xml`. On découpe
    /// donc sur ce marqueur, puis on limite chaque fragment à son `</plist>`
    /// — sinon les quelques octets qui suivent (retour à la ligne, prochaine
    /// déclaration) gêneraient l'analyseur.
    private static func powerSourcePlistEntries(_ output: String) -> [[String: Any]] {
        var entries: [[String: Any]] = []
        for fragment in output.components(separatedBy: "<?xml").dropFirst() {
            guard let end = fragment.range(of: "</plist>") else { continue }
            let xml = "<?xml" + fragment[fragment.startIndex..<end.upperBound]
            guard let data = xml.data(using: .utf8),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                  let dictionary = plist as? [String: Any]
            else { continue }
            entries.append(dictionary)
        }
        return entries
    }

    /// Exécute `pmset -g accps -xml` et renvoie sa sortie standard.
    private static func accessoryPowerSources() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "accps", "-xml"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        // Lire jusqu'à EOF **avant** d'attendre la fin évite tout blocage si
        // la sortie dépassait la taille du tampon du pipe.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }
}
