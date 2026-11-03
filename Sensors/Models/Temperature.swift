//
//  Temperature.swift
//  HAL
//
//  Modèle pour les températures.
//

/// Représente les températures du système
public struct Temperature: Sendable {
    // swiftlint:disable implicit_optional_initialization
    /// Température moyenne du SoC
    public var socAverage: Double? = nil
    /// Température maximale du SoC
    public var socPeak: Double? = nil
    // swiftlint:enable implicit_optional_initialization

    /// Nombre de dies
    public var dieCount: Int = 0

    public init() {}

    public init(socAverage: Double?, socPeak: Double?, dieCount: Int) {
        self.socAverage = socAverage
        self.socPeak = socPeak
        self.dieCount = dieCount
    }
}
