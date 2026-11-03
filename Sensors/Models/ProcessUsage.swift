//
//  ProcessUsage.swift
//  HAL
//
//  Modèle pour l'utilisation d'un processus.
//

/// Charge d'un processus
public struct ProcessUsage: Sendable {
    public var name: String = ""
    /// Identifiant du processus
    public var pid: Int32 = 0
    /// Charge CPU en pourcentage
    public var cpu: Double = 0
    /// Mémoire résidente (RSS) en octets
    public var memory: Double = 0

    public init() {}

    public init(name: String, pid: Int32, cpu: Double, memory: Double) {
        self.name = name
        self.pid = pid
        self.cpu = cpu
        self.memory = memory
    }
}
