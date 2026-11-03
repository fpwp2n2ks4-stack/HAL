//
//  CPUUsage.swift
//  HAL
//
//  Modèle pour l'utilisation du CPU.
//

/// Représente l'utilisation du CPU
public struct CPUUsage: Sendable {
    /// Charge CPU totale en pourcentage (0...100)
    public var total: Double = 0
    /// Charge par cœur en pourcentage
    public var perCore: [Double] = []

    public init() {}

    public init(total: Double, perCore: [Double]) {
        self.total = total
        self.perCore = perCore
    }
}
