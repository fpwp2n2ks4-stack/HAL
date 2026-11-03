//
//  NetworkReader.swift
//  HAL
//
//  Lecteur de l'utilisation du réseau.
//  Utilise une file dédiée pour la synchronisation thread-safe.
//

import Foundation

/// Lecteur de l'utilisation du réseau
/// Utilise un acteur pour la synchronisation thread-safe
public struct Counters: Sendable {
    var rxBytes: UInt32 = 0
    var txBytes: UInt32 = 0
}

private final actor NetworkReaderState {
    var previous: [String: Counters] = [:]
    var lastTimestamp: Date?

    func update(current: [String: Counters], timestamp: Date) {
        previous = current
        lastTimestamp = timestamp
    }
}

public final class NetworkReader {
    private let state = NetworkReaderState()

    // Interfaces à ignorer
    private static let ignored: Set<String> = [
        "lo0", "awdl0", "llw0", "bridge0", "anpi0", "gif0", "stf0",
        "utun0", "utun1", "utun2", "utun3", "utun4", "utun5",
        "vmnet1", "vmnet2", "vmnet3", "vnic0", "ap1"
    ]

    private static let watchdog: TimeInterval = 5

    public init() {}

    // MARK: - Public Methods

    /// Lit l'utilisation actuelle du réseau
    /// - Returns: NetworkUsage avec les débits de téléchargement et upload
    public func read() async throws -> NetworkUsage {
        let current = try await Self.collect()
        let now = Date()

        // Lire les valeurs précédentes de manière thread-safe via l'acteur
        let previousCopy = await state.previous
        let lastTimestampCopy = await state.lastTimestamp

        // Le débit a besoin d'un intervalle
        guard let last = lastTimestampCopy else {
            await state.update(current: current, timestamp: now)
            return NetworkUsage()
        }

        let elapsed = now.timeIntervalSince(last)
        guard elapsed > 0 else {
            return NetworkUsage()
        }

        var down: Double = 0
        var upload: Double = 0
        var best: (String, Double)?

        for (name, counters) in current where !Self.ignored.contains(name) {
            guard let old = previousCopy[name] else { continue }
            // Gestion du overflow des compteurs 32 bits
            let deltaDown = Double(counters.rxBytes &- old.rxBytes)
            let deltaUp = Double(counters.txBytes &- old.txBytes)
            down += deltaDown
            upload += deltaUp
            let total = deltaDown + deltaUp
            if total > 0, best == nil || total > best!.1 {
                best = (name, total)
            }
        }

        // Mettre à jour de manière thread-safe
        await state.update(current: current, timestamp: now)

        return NetworkUsage(
            downloadPerSecond: down / elapsed,
            uploadPerSecond: upload / elapsed,
            activeInterface: best?.0
        )
    }

    // MARK: - Private Methods

    /// Collecte les compteurs réseau de toutes les interfaces
    private static func collect() async throws -> [String: Counters] {
        var list: [String: Counters] = [:]

        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else {
            throw ReaderError.systemCallFailed(code: errno, function: "getifaddrs")
        }
        defer { freeifaddrs(head) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let node = cursor {
            let interface = node.pointee
            if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                let name = String(cString: interface.ifa_name)
                // ifi_ibytes/ifi_obytes sont des entiers 32 bits signés
                list[name] = Counters(
                    rxBytes: UInt32(truncatingIfNeeded: data.pointee.ifi_ibytes),
                    txBytes: UInt32(truncatingIfNeeded: data.pointee.ifi_obytes)
                )
            }
            cursor = interface.ifa_next
        }

        return list
    }
}
