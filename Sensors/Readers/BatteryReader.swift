//
//  BatteryReader.swift
//  HAL
//
//  Lecteur de l'état de la batterie.
//

import Foundation
import IOKit.ps

/// Lecteur de l'état de la batterie
public struct BatteryReader: Sendable {

    public init() {}

    /// Lit l'état actuel de la batterie
    /// - Returns: BatteryStatus avec toutes les informations de la batterie
    public func read() async throws -> BatteryStatus {
        // Lecture des propriétés SmartBattery
        let hardware = smartBatteryProperties()

        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              let first = list.first,
              let description = IOPSGetPowerSourceDescription(info, first)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatteryStatus()
        }

        let level = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let charging = description[kIOPSIsChargingKey as String] as? Bool ?? false
        let plugged = description[kIOPSPowerSourceStateKey as String] as? String == kIOPSACPowerValue

        let remaining = timeRemaining(description, charging: charging)

        // Détails matériels
        let chargerData = hardware["ChargerData"] as? [String: Any]
        let capacity = capacities(hardware: hardware)
        let design = capacity.design
        let maximum = capacity.maximum

        let health = design > 0
            ? min(100, Int((100.0 * Double(maximum) / Double(design)).rounded()))
            : 0

        // Adaptateur
        let adapter = adapterDetails(plugged: plugged, hardware: hardware)

        return BatteryStatus(
            level: level,
            isCharging: charging,
            isPlugged: plugged,
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            timeRemainingMinutes: (remaining ?? 0) > 0 ? remaining : nil,
            isPresent: true,
            notChargingReason: intValue(chargerData?["NotChargingReason"]) ?? 0,
            health: health,
            cycles: intValue(hardware["CycleCount"]) ?? 0,
            maxCapacityMah: maximum,
            designCapacityMah: design,
            voltage: (doubleValue(hardware["Voltage"]) ?? 0) / 1000,
            amperage: doubleValue(hardware["Amperage"]) ?? 0,
            adapterWatts: adapter.watts,
            adapterVoltage: adapter.voltage
        )
    }

    // MARK: - Découpages de la lecture

    /// Temps restant, en minutes : jusqu'à la pleine charge si on charge,
    /// jusqu'à la décharge sinon. Une charge presque terminée n'a pas de
    /// temps fiable.
    private func timeRemaining(_ description: [String: Any], charging: Bool) -> Int? {
        if charging {
            if let full = description[kIOPSIsFinishingChargeKey as String] as? Bool, full {
                return nil
            }
            return description["Time to Full Charge" as String] as? Int
        }
        return description[kIOPSTimeToEmptyKey as String] as? Int
    }

    /// Capacités de design et de pleine charge, avec les replis historiques
    /// de clés selon la génération du matériel.
    private func capacities(hardware: [String: Any]) -> (design: Int, maximum: Int) {
        let batteryData = hardware["BatteryData"] as? [String: Any]
        let design = intValue(hardware["DesignCapacity"])
            ?? intValue(batteryData?["DesignCapacity"])
            ?? 0
        let maximum = intValue(hardware["AppleRawMaxCapacity"])
            ?? intValue(batteryData?["FullChargeCapacity"])
            ?? intValue(batteryData?["NominalChargeCapacity"])
            ?? 0
        return (design, maximum)
    }

    /// Adaptateur secteur : puissance et tension, nulles sur batterie.
    private func adapterDetails(plugged: Bool, hardware: [String: Any]) -> (watts: Int, voltage: Double) {
        let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
        let details = hardware["AdapterDetails"] as? [String: Any]
        let watts = intValue(adapter?["Watts"])
            ?? intValue(details?["Watts"])
            ?? 0
        let voltage = plugged
            ? Double(intValue(details?["AdapterVoltage"]) ?? 0) / 1000
            : 0
        return (watts, voltage)
    }

    // MARK: - Private Helpers

    private func smartBatteryProperties() -> [String: Any] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery"),
            &iterator
        ) == kIOReturnSuccess else {
            return [:]
        }
        let service = IOIteratorNext(iterator)
        IOObjectRelease(iterator)
        guard service != 0 else { return [:] }
        defer { IOObjectRelease(service) }

        var reference: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            service,
            &reference,
            kCFAllocatorDefault,
            0
        ) == kIOReturnSuccess,
              let dictionary = reference?.takeRetainedValue() as? [String: Any]
        else {
            return [:]
        }
        return dictionary
    }

    private func intValue(_ value: Any?) -> Int? {
        (value as? NSNumber)?.intValue
    }

    private func doubleValue(_ value: Any?) -> Double? {
        (value as? NSNumber)?.doubleValue
    }
}
