//
//  GPUUsage.swift
//  HAL
//
//  Modèle pour l'utilisation du GPU.
//

/// Représente l'utilisation du GPU
public struct GPUUsage: Sendable {
    /// Utilisation du périphérique en pourcentage (0...100)
    public var deviceUtilization: Int = 0
    /// Mémoire utilisée en octets
    public var inUseMemory: Double = 0

    public init() {}

    public init(deviceUtilization: Int, inUseMemory: Double) {
        self.deviceUtilization = deviceUtilization
        self.inUseMemory = inUseMemory
    }
}
