//
//  NetworkUsage.swift
//  HAL
//
//  Modèle pour l'utilisation du réseau.
//

import Foundation

/// Représente l'utilisation du réseau
public struct NetworkUsage: Sendable {
    /// Téléchargement en octets/seconde (somme des interfaces actives)
    public var downloadPerSecond: Double = 0
    /// Téléchargement en octets/seconde
    public var uploadPerSecond: Double = 0
    /// Interface active ("en0", "en1", etc.)
    public var activeInterface: String?

    public init() {}

    public init(downloadPerSecond: Double, uploadPerSecond: Double, activeInterface: String?) {
        self.downloadPerSecond = downloadPerSecond
        self.uploadPerSecond = uploadPerSecond
        self.activeInterface = activeInterface
    }

    /// Calcule la fraction de charge en fonction du débit.
    /// L'échelle est logarithmique car les pics de transfert sont temporaires.
    /// - Parameter bytesPerSecond: le débit le plus élevé (téléchargement ou upload)
    /// - Returns: Fraction de charge (0...1)
    public static func loadFraction(bytesPerSecond: Double) -> Double {
        guard bytesPerSecond > 0 else { return 0 }
        let normalized = log10(1 + bytesPerSecond / 100_000) / 2
        return min(1, max(0, normalized))
    }
}
