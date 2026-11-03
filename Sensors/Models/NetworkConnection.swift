//
//  NetworkConnection.swift
//  HAL
//
//  Modèle pour une connexion réseau.
//

/// Une connexion réseau observée sur la machine
public struct NetworkConnection: Sendable {
    /// Nom du processus
    public var process: String = ""
    /// PID du processus
    public var pid: Int32 = 0
    /// Adresse locale, port compris
    public var local: String = ""
    /// Adresse distante, port compris
    public var remote: String = ""
    /// État TCP
    public var state: String = ""
    /// Le processus écoute sur ce port
    public var isListening: Bool = false
    /// Socket ni en écoute ni reliée à un pair
    public var isDetached: Bool = false
    /// Sens de la connexion : entrante ou sortante
    public var isIncoming: Bool = false
    /// Interface réseau
    public var interface: String?

    public init() {}

    public init(
        process: String = "",
        pid: Int32 = 0,
        local: String = "",
        remote: String = "",
        state: String = "",
        isListening: Bool = false,
        isDetached: Bool = false,
        isIncoming: Bool = false,
        interface: String? = nil
    ) {
        self.process = process
        self.pid = pid
        self.local = local
        self.remote = remote
        self.state = state
        self.isListening = isListening
        self.isDetached = isDetached
        self.isIncoming = isIncoming
        self.interface = interface
    }
}
