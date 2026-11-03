//
//  ConnectionReader.swift
//  HAL
//
//  Lecture des connexions réseau, entrantes et sortantes.
//  Récupéré de l'ancien `Sensors/Sensors.swift`, adapté à l'architecture
//  modulaire (le relevé reste asynchrone et jamais bloquant).
//

import Foundation

/// Lit les connexions réseau, entrantes et sortantes.
///
/// ## Pourquoi `lsof` seul — et pas `netstat`
///
/// `netstat` semble le choix évident : il liste **toutes** les connexions
/// TCP, y compris celles de `root` et des autres utilisateurs. Mais il
/// porte l'entitlement privé `com.apple.private.network.statistics`, et
/// mesuré sur cette machine, lancé depuis un binaire non autorisé, il
/// **réussit sans rien écrire** (statut 0, zéro octet) — pipe, fichier ou
/// terminal, toujours zéro. Ce n'est pas un buffering : c'est un refus
/// silencieux. Inexploitable sans privilèges Apple.
///
/// `lsof -nP -i`, lui, fonctionne et donne tout ce qu'il faut en une passe :
/// nom, PID, adresses locale et distante, état TCP. Sa limite est connue et
/// assumée : **il ne voit que les connexions de l'utilisateur courant**. Un
/// agent de barre de menus n'a pas à faire mieux — et le cockpit n'affiche
/// que ce qu'il voit réellement, plutôt qu'une totalité qu'il n'obtiendrait
/// qu'en réclamant des droits qu'il n'a pas.
///
/// ## Pourquoi un cache
///
/// Un relevé lance `lsof` (~50 ms mesurés). Le faire à chaque tick de 2 s
/// serait payé sans rien apporter : une table de connexions ne change pas à
/// cette cadence. `read()` renvoie donc le cache, et un relevé de fond le
/// rafraîchit au plus une fois par `timeToLive`. Jamais bloquant.
public final class ConnectionReader: @unchecked Sendable {

    /// Durée de validité du cache, en secondes.
    private static let timeToLive: TimeInterval = 5

    /// Délai au-delà duquel un relevé est considéré comme bloqué et tué.
    private static let watchdog: TimeInterval = 5

    private let lock = NSLock()
    private let queue = DispatchQueue(label: "HAL.Connections", qos: .utility)
    private var cached: [NetworkConnection] = []
    private var lastFetch: Date = .distantPast
    private var isFetching = false

    public init() {}

    // MARK: - Public Methods

    /// Connexions en cache, rafraîchies en arrière-plan. **Jamais bloquant.**
    public func read() async -> [NetworkConnection] {
        queue.async { self.refresh() }
        return lock.withLock { cached }
    }

    // MARK: - Private Methods

    /// Relevé sur la file de fond : saute si un est en cours ou si le cache
    /// est encore bon. Ne doit être appelé que depuis `queue`.
    private func refresh() {
        let now = Date()
        lock.lock()
        let takeOver = !isFetching && now.timeIntervalSince(lastFetch) >= Self.timeToLive
        if takeOver { isFetching = true }
        lock.unlock()
        guard takeOver else { return }

        let connections = Self.fetch()
        lock.lock()
        cached = connections
        isFetching = false
        lastFetch = now
        lock.unlock()
    }

    // MARK: Lecture

    /// Une passe de `lsof`, une ligne par socket.
    ///
    /// Le relevé se fait en **deux temps** : on lit d'abord toutes les
    /// lignes brutes, on en tire l'ensemble des ports en écoute (les
    /// `LISTEN`), puis on classe chaque conversation. La raison est que le
    /// sens d'une conversation ne se lit pas dans sa ligne : il se déduit
    /// de la liste des écoutes — un pair arrivé sur un port que le
    /// processus écoute est **entrant**, tout le reste est **sortant**.
    private static func fetch() -> [NetworkConnection] {
        var connections: [NetworkConnection] = []
        for line in run("/usr/sbin/lsof", ["-nP", "-i"]) {
            if let connection = parse(line) { connections.append(connection) }
        }

        // Ports en écoute, **sans le nom de processus**. Le nom ne doit pas
        // faire partie de la clé : une connexion acceptée peut vivre dans
        // un autre processus que celui qui écoute — démon lancé par un
        // démon une-connexion-un-processus, socket passée par launchd,
        // service XPC… (relevé réel : `handlerX …:10500->…` côté entrant
        // pendant que `Python …:10500 (LISTEN)` détient l'écoute : classée
        // sortante avec une clé « nom:port », entrante avec le port seul).
        // TCP garantit qu'une socket acceptée porte le port d'écoute en
        // local ; et le noyau n'attribue pas de port éphémère déjà occupé
        // par une écoute, donc une connexion sortante ne peut pas porter
        // par hasard un port écouté sur le même jeu d'adresses.
        var listening: Set<String> = []
        for connection in connections where connection.isListening {
            if let port = Self.port(of: connection.local) { listening.insert(port) }
        }

        for index in connections.indices where !connections[index].isListening {
            let connection = connections[index]
            guard !connection.remote.isEmpty else { continue }
            let isIncoming = Self.port(of: connection.local).map { listening.contains($0) } ?? false
            connections[index].isIncoming = isIncoming
        }

        return connections.sorted(by: inReadingOrder)
    }

    /// Port d'une adresse `lsof` (« *:50064 », « 10.0.0.2:54321 »,
    /// « [::1]:443 ») : les chiffres après le dernier deux-points.
    private static func port(of address: String) -> String? {
        guard let colon = address.lastIndex(of: ":") else { return nil }
        let port = address[address.index(after: colon)...]
        let digits = port.prefix { $0.isNumber }
        return digits.isEmpty ? nil : String(digits)
    }

    /// Ordre d'affichage stable d'un relevé à l'autre : les conversations
    /// établies d'abord (c'est ce qui vit), puis les autres états, puis les
    /// écoutes, puis les sockets détachées ; à état égal, par nom de
    /// processus puis par pair.
    private static func inReadingOrder(_ first: NetworkConnection,
                                       _ second: NetworkConnection) -> Bool {
        func rank(_ connection: NetworkConnection) -> Int {
            if connection.isListening { return 2 }
            if connection.isDetached { return 3 }
            return connection.state == "ESTABLISHED" ? 0 : 1
        }
        if rank(first) != rank(second) { return rank(first) < rank(second) }
        if first.process != second.process { return first.process < second.process }
        return first.remote < second.remote
    }

    /// Une ligne de `lsof -nP -i`, dont la forme est stable :
    ///
    /// ```text
    /// COMMAND  PID USER FD TYPE DEVICE       SIZE/OFF NODE NAME
    /// rapportd 654 arch 22u IPv4 0x8b52...   0t0     TCP  192.168.1.156:50064->192.168.1.127:50702 (ESTABLISHED)
    /// rapportd 654 arch  9u IPv4 0x4294...   0t0     TCP  *:50064 (LISTEN)
    /// rapportd 654 arch 24u IPv4 0x8af4...   0t0     UDP  *:3722
    /// ```
    ///
    /// Le champ `NODE` vaut `TCP`, `UDP` ou `SCTP` ; le `NAME` le suit, et
    /// l'éventuel état est le **dernier** champ, entre parenthèses. Trois
    /// pièges, tous rencontrés :
    ///
    /// - `COMMAND` est tronqué à 9 caractères et peut contenir des espaces :
    ///   on ne compte donc **jamais** les champs depuis la gauche, sauf PID
    ///   (toujours en 2ᵉ) et protocole, qu'on cherche.
    /// - l'état est absent pour UDP : il ne faut pas le confondre avec le
    ///   NAME.
    /// - un NAME **avec** espace est répété d'un bloc par `lsof` ; nos NAME
    ///   d'adresses n'en ont pas, mais la règle « tout ce qui suit le
    ///   protocole, moins l'état final » reste juste dans les deux cas.
    private static func parse(_ line: String) -> NetworkConnection? {
        let fields = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard fields.count >= 9 else { return nil }
        guard let pid = Int32(fields[1]) else { return nil }   // l'en-tête « PID » est rejeté ici

        // Protocole de transport : ancre le NAME.
        guard let transport = fields.firstIndex(where: {
            $0 == "TCP" || $0 == "UDP" || $0 == "SCTP"
        }), transport + 1 < fields.count else { return nil }

        // État final, si présent : dernier champ commençant par « ( ».
        var payloadFields = Array(fields[(transport + 1)...])
        var state = ""
        if let last = payloadFields.last, last.hasPrefix("("), last.hasSuffix(")") {
            state = String(last.dropFirst().dropLast())
            payloadFields.removeLast()
        }
        // Ce qui reste est le NAME, espaces recomposées : les adresses n'en
        // ont pas, mais `lsof` ne garantit pas qu'une valeur n'en porte pas.
        let endpoints = payloadFields.joined(separator: " ")
        let isListening = state == "LISTEN"

        let local: String
        let remote: String
        if let arrow = endpoints.range(of: "->") {
            local = String(endpoints[endpoints.startIndex..<arrow.lowerBound])
            remote = String(endpoints[arrow.upperBound...]).trimmingCharacters(in: .whitespaces)
        } else {
            local = endpoints.trimmingCharacters(in: .whitespaces)
            remote = ""
        }

        var connection = NetworkConnection()
        connection.process = fields[0]
        connection.pid = pid
        connection.local = local
        connection.remote = remote
        connection.state = state
        connection.isListening = isListening
        // Le sens n'est **pas** décidable sur une seule ligne : il est
        // renseigné plus tard, dans `fetch()`, par confrontation à la liste
        // des écoutes. Une socket ni en écoute ni pourvue d'un pair (UDP
        // non connectée, « *:* ») n'est d'aucun des deux bords.
        connection.isDetached = !isListening && remote.isEmpty
        return connection
    }

    /// Lance un outil et renvoie ses lignes. Un échec (outil absent) rend
    /// une liste vide : le panneau affichera « rien », jamais une erreur.
    private static func run(_ path: String, _ arguments: [String]) -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return []
        }
        // Chien de garde, comme partout ailleurs : un outil figé ne doit
        // pas retenir la file de fond ni bloquer `isFetching`.
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + watchdog) {
            if process.isRunning { process.terminate() }
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            return []
        }
        return String(data: data, encoding: .utf8)?
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init) ?? []
    }
}
