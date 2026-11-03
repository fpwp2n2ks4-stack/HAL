//
//  BatteryStatus.swift
//  HAL
//
//  Modèle pour l'état de la batterie.
//

/// Représente l'état de la batterie
public struct BatteryStatus: Sendable {
    // swiftlint:disable implicit_optional_initialization
    // `= nil` est explicite ici parce que ces propriétés sont publiques :
    // la valeur par défaut fait partie de l'API

    /// Niveau de batterie en pourcentage (0...100)
    public var level: Int = 0
    /// La batterie est en train de charger
    public var isCharging: Bool = false
    /// L'adaptateur est branché
    public var isPlugged: Bool = false
    /// Mode économie d'énergie actif
    public var isLowPowerMode: Bool = false
    /// Temps restant en minutes
    public var timeRemainingMinutes: Int? = nil
    /// La batterie est présente
    public var isPresent: Bool = false
    /// Motif pour lequel macOS refuse de charger
    public var notChargingReason: Int = 0

    // MARK: Détails matériels

    /// Santé en pourcentage : capacité maximale actuelle rapportée à la capacité d'origine
    public var health: Int = 0
    /// Nombre de cycles de charge
    public var cycles: Int = 0
    /// Capacité maximale actuelle, en mAh
    public var maxCapacityMah: Int = 0
    /// Capacité d'origine (conçue), en mAh
    public var designCapacityMah: Int = 0
    /// Tension de la batterie, en volts
    public var voltage: Double = 0
    /// Courant de la batterie, en milliampères (négatif en décharge)
    public var amperage: Double = 0
    /// Puissance nominale du chargeur, en watts
    public var adapterWatts: Int = 0
    /// Tension négociée de l'adaptateur, en volts
    public var adapterVoltage: Double = 0

    // swiftlint:enable implicit_optional_initialization

    /// Puissance instantanée de la batterie, en watts
    public var power: Double {
        voltage * amperage / 1000
    }

    /// macOS retient la charge (seuil atteint ou charge optimisée)
    public var isAtChargeLimit: Bool {
        notChargingReason & Self.chargeLimitBit != 0
    }

    /// Bit 24 — « macOS retient la charge »
    private static let chargeLimitBit = 0x0100_0000

    public init() {}

    public init(
        level: Int = 0,
        isCharging: Bool = false,
        isPlugged: Bool = false,
        isLowPowerMode: Bool = false,
        timeRemainingMinutes: Int? = nil,
        isPresent: Bool = false,
        notChargingReason: Int = 0,
        health: Int = 0,
        cycles: Int = 0,
        maxCapacityMah: Int = 0,
        designCapacityMah: Int = 0,
        voltage: Double = 0,
        amperage: Double = 0,
        adapterWatts: Int = 0,
        adapterVoltage: Double = 0
    ) {
        self.level = level
        self.isCharging = isCharging
        self.isPlugged = isPlugged
        self.isLowPowerMode = isLowPowerMode
        self.timeRemainingMinutes = timeRemainingMinutes
        self.isPresent = isPresent
        self.notChargingReason = notChargingReason
        self.health = health
        self.cycles = cycles
        self.maxCapacityMah = maxCapacityMah
        self.designCapacityMah = designCapacityMah
        self.voltage = voltage
        self.amperage = amperage
        self.adapterWatts = adapterWatts
        self.adapterVoltage = adapterVoltage
    }
}
