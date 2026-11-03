//
//  MemoryUsage.swift
//  HAL
//
//  Modèle pour l'utilisation de la mémoire.
//

/// Représente l'utilisation de la mémoire
public struct MemoryUsage: Sendable {
    /// Mémoire utilisée en octets
    public var used: Double = 0
    /// Mémoire totale en octets
    public var total: Double = 0
    /// Mémoire compressée en octets
    public var compressed: Double = 0
    /// Mémoire wired en octets
    public var wired: Double = 0

    /// Fraction de mémoire utilisée (0...1)
    public var fraction: Double {
        total > 0 ? used / total : 0
    }

    public init() {}

    public init(used: Double, total: Double, compressed: Double, wired: Double) {
        self.used = used
        self.total = total
        self.compressed = compressed
        self.wired = wired
    }
}
