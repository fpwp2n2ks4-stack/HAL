//
//  ProcessReader.swift
//  HAL
//
//  Lecture des processus les plus gourmands, par CPU puis par mémoire.
//  Récupéré de l'ancien `Sensors/Sensors.swift`, adapté à l'architecture
//  modulaire (état de la lecture précédente dans un acteur).
//

import Foundation
import Darwin

private struct ProcessSample: Sendable {
    var cpuTime: UInt64
    var memory: UInt64
}

/// Lecteur des processus les plus gourmands.
///
/// La charge CPU d'un processus ne se lit pas en absolu : `proc_taskinfo`
/// expose un temps CPU **cumulé**, qu'il faut rapporter au temps réel
/// écoulé depuis la lecture précédente. La première lecture donne donc
/// toujours 0 % — c'est seulement à partir de la deuxième que la charge
/// est réelle.
public final class ProcessReader {

    /// État de la lecture précédente, synchronisé par un acteur.
    private final actor State {
        var previous: [Int32: ProcessSample] = [:]
        var lastDate: Date?

        func update(current: [Int32: ProcessSample], date: Date) {
            previous = current
            lastDate = date
        }
    }

    private let state = State()

    /// Nombre de nanosecondes par tick mach, une fois pour tout le processus.
    ///
    /// `mach_timebase_info` renvoie une fraction `numer/denom` : sur Apple
    /// Silicon `125/3` (≈ 41,67 ns/tick), sur Intel `1/1` (1 ns/tick).
    private static let nanosecondsPerTick: Double = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        guard info.denom != 0 else { return 1 }
        return Double(info.numer) / Double(info.denom)
    }()

    public init() {}

    // MARK: - Public Methods

    /// Les `limit` processus les plus gourmands, triés par CPU puis mémoire.
    /// - Parameter limit: nombre maximum de processus renvoyés
    /// - Returns: les processus, la charge CPU étant mesurée depuis la
    ///   lecture précédente
    public func read(limit: Int = 10) async -> [ProcessUsage] {
        let now = Date()
        let previous = await state.previous
        let lastDate = await state.lastDate
        let elapsed = lastDate.map { now.timeIntervalSince($0) } ?? 0

        var current: [Int32: ProcessSample] = [:]
        var usages: [ProcessUsage] = []
        let secondsNanoseconds = 1_000_000_000.0

        for pid in Self.allPIDs() where pid > 0 {
            var info = proc_taskinfo()
            let size = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info,
                                    Int32(MemoryLayout<proc_taskinfo>.size))
            guard size > 0 else { continue }

            let sample = ProcessSample(cpuTime: info.pti_total_user &+ info.pti_total_system,
                                memory: info.pti_resident_size)
            current[pid] = sample

            // Un PID réutilisé peut afficher un compteur plus petit : dans ce
            // cas la différence serait absurde, on repart de zéro.
            var cpu: Double = 0
            if elapsed > 0, let old = previous[pid], sample.cpuTime >= old.cpuTime {
                // `cpuTime` est en ticks mach : on le ramène en nanosecondes
                // avant de le rapporter au temps réel écoulé.
                let nanoseconds = Double(sample.cpuTime - old.cpuTime) * Self.nanosecondsPerTick
                cpu = nanoseconds / (elapsed * secondsNanoseconds) * 100
            }

            usages.append(ProcessUsage(name: Self.name(for: pid) ?? "pid \(pid)",
                                       pid: Int32(pid),
                                       cpu: cpu,
                                       memory: Double(sample.memory)))
        }

        await state.update(current: current, date: now)

        return Array(usages
            .sorted { $0.cpu == $1.cpu ? $0.memory > $1.memory : $0.cpu > $1.cpu }
            .prefix(limit))
    }

    // MARK: - Private Methods

    /// Liste des PID, dimensionnée par un premier appel qui ne remplit rien.
    ///
    /// `proc_listallpids(nil, 0)` renvoie le **nombre** de PID (le wrapper
    /// libproc divise déjà la taille d'octets par `sizeof(int)`). Le second
    /// appel renvoie le nombre réellement écrit, qui peut être plus petit si
    /// des processus ont disparu entre-temps.
    static func allPIDs() -> [pid_t] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(count))
        let written = pids.withUnsafeMutableBufferPointer { buffer in
            proc_listallpids(buffer.baseAddress,
                             Int32(buffer.count * MemoryLayout<pid_t>.stride))
        }
        guard written > 0 else { return [] }
        return Array(pids.prefix(Int(written)))
    }

    /// Nom court du processus (`proc_name`), ou `nil` s'il n'est pas lisible.
    static func name(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 256)
        guard proc_name(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(cString: buffer)
    }
}
