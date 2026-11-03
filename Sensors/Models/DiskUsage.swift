//
//  DiskUsage.swift
//  HAL
//
//  Modèle pour l'utilisation du disque.
//

/// Occupation et activité du disque de démarrage.
public struct DiskUsage: Sendable {
    /// Le volume racine est présent
    public var isPresent: Bool = false
    /// Espace occupé en octets
    public var used: Double = 0
    /// Capacité totale en octets
    public var total: Double = 0
    /// Espace libre en octets
    public var free: Double = 0
    /// Type du système de fichiers
    public var fileSystem: String = ""

    /// Débit lecture en octets/seconde
    public var readPerSecond: Double = 0
    /// Débit écriture en octets/seconde
    public var writePerSecond: Double = 0

    /// Température du SSD en °C
    public var smartTemperature: Double?
    /// Santé du SSD en pourcentage
    public var smartHealth: Int?

    /// Fraction d'utilisation (0...1)
    public var fraction: Double {
        total > 0 ? used / total : 0
    }

    public init() {}

    public init(
        isPresent: Bool = false,
        used: Double = 0,
        total: Double = 0,
        free: Double = 0,
        fileSystem: String = "",
        readPerSecond: Double = 0,
        writePerSecond: Double = 0,
        smartTemperature: Double? = nil,
        smartHealth: Int? = nil
    ) {
        self.isPresent = isPresent
        self.used = used
        self.total = total
        self.free = free
        self.fileSystem = fileSystem
        self.readPerSecond = readPerSecond
        self.writePerSecond = writePerSecond
        self.smartTemperature = smartTemperature
        self.smartHealth = smartHealth
    }
}
