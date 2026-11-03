//
//  SnapshotReader.swift
//  HAL
//
//  Lecteur principal qui orchestrer tous les readers pour créer un Snapshot.
//

import Foundation

public enum SnapshotError: Error, LocalizedError {
    case partialRead(failedReaders: [String])
    case allReadersFailed

    public var errorDescription: String? {
        switch self {
        case .partialRead(let failedReaders):
            return "Partial snapshot read. Failed readers: {\((failedReaders.joined(separator: ", ")))}"
        case .allReadersFailed:
            return "All readers failed to read data"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .partialRead:
            return "Some system metrics are unavailable. Check system permissions."
        case .allReadersFailed:
            return "All system metrics are unavailable. Check system permissions and hardware support."
        }
    }
}

/// Lecteur principal qui crée des snapshots complets du système
public final class SnapshotReader: @unchecked Sendable {

    // Readers par défaut
    private let cpuReader: CPUReader
    private let memoryReader: MemoryReader
    private let networkReader: NetworkReader
    private let batteryReader: BatteryReader
    private let temperatureReader: TemperatureReader?
    private let gpuReader: GPUReader
    private let diskReader: DiskReader
    private let processReader: ProcessReader
    private let connectionReader: ConnectionReader
    private let nowPlayingReader: NowPlayingReader
    private let bluetoothReader = BluetoothReader()

    // Cache pour les lectures fréquentes
    private var lastSnapshot: Snapshot?
    private var lastReadTime: Date = .distantPast
    private let minimumReadInterval: TimeInterval = 0.5
    private let lock = NSLock()

    // MARK: - Lifecycle

    /// Initialise le SnapshotReader avec des readers par défaut
    public init() async {
        // Initialiser les readers réels
        let realCPUReader = await CPUReader()
        let realMemoryReader = MemoryReader()
        let realNetworkReader = NetworkReader()
        let realBatteryReader = BatteryReader()

        let realTemperatureReader: TemperatureReader?
        do {
            realTemperatureReader = try TemperatureReader()
        } catch {
            Logger.warning("Temperature reader unavailable: {\((error))}", category: .sensors)
            realTemperatureReader = nil
        }

        self.cpuReader = realCPUReader
        self.memoryReader = realMemoryReader
        self.networkReader = realNetworkReader
        self.batteryReader = realBatteryReader
        self.temperatureReader = realTemperatureReader
        self.gpuReader = GPUReader()
        self.diskReader = DiskReader()
        self.processReader = ProcessReader()
        self.connectionReader = ConnectionReader()
        self.nowPlayingReader = NowPlayingReader()

        // Lire le premier snapshot
        _ = try? await readSnapshot()
    }

    /// Initialise avec des readers injectés (pour les tests)
    internal init(
        cpuReader: CPUReader,
        memoryReader: MemoryReader,
        networkReader: NetworkReader,
        batteryReader: BatteryReader,
        temperatureReader: TemperatureReader?,
        gpuReader: GPUReader,
        diskReader: DiskReader
    ) {
        self.cpuReader = cpuReader
        self.memoryReader = memoryReader
        self.networkReader = networkReader
        self.batteryReader = batteryReader
        self.temperatureReader = temperatureReader
        self.gpuReader = gpuReader
        self.diskReader = diskReader
        self.processReader = ProcessReader()
        self.connectionReader = ConnectionReader()
        self.nowPlayingReader = NowPlayingReader()
    }

    // MARK: - Public Methods

    /// Lit un nouveau snapshot du système
    /// - Returns: Snapshot avec toutes les métriques
    public func readSnapshot() async throws -> Snapshot {
        if let cached = cachedSnapshot() {
            return cached
        }

        Logger.debug("Reading new snapshot...", category: .sensors)

        // Processus et connexions : jamais en erreur, au pire vides. La
        // première lecture des processus donne 0 % (pas de passé), la
        // première lecture des connexions rend le cache vide le temps
        // du premier relevé `lsof`. Les autres lectures sont lancées
        // comme tâches concurrentes.
        let cpuTask = retryTask({ await self.cpuReader.read() }, name: "CPU")
        let memoryTask = retryTask({ try await self.memoryReader.read() }, name: "Memory")
        let networkTask = retryTask({ try await self.networkReader.read() }, name: "Network")
        let batteryTask = retryTask({ try await self.batteryReader.read() }, name: "Battery")
        let temperatureTask = Task { try await self.readTemperature() }
        let gpuTask = retryTask({ try await self.gpuReader.read() }, name: "GPU")
        let diskTask = retryTask({ try await self.diskReader.read() }, name: "Disk")
        let processesTask = Task { await self.processReader.read() }
        let connectionsTask = Task { await self.connectionReader.read() }
        let nowPlayingTask = Task { await self.nowPlayingReader.read() }
        let bluetoothTask = Task { self.bluetoothReader.read() }

        var errors: [String] = []
        let cpu = await readOrDefault(cpuTask, name: "CPU", fallback: CPUUsage(), errors: &errors)
        let memory = await readOrDefault(memoryTask, name: "Memory", fallback: MemoryUsage(), errors: &errors)
        let network = await readOrDefault(networkTask, name: "Network", fallback: NetworkUsage(), errors: &errors)
        let battery = await readOrDefault(batteryTask, name: "Battery", fallback: BatteryStatus(), errors: &errors)
        let temperature = await readOrDefault(
            temperatureTask, name: "Temperature", fallback: Temperature(), errors: &errors)
        let gpu = await readOrDefault(gpuTask, name: "GPU", fallback: GPUUsage(), errors: &errors)
        let disk = await readOrDefault(diskTask, name: "Disk", fallback: DiskUsage(), errors: &errors)

        let snapshot = Snapshot(
            cpu: cpu,
            memory: memory,
            network: network,
            disk: disk,
            battery: battery,
            gpu: gpu,
            temperature: temperature,
            processes: await processesTask.value,
            bluetooth: await bluetoothTask.value,
            nowPlaying: await nowPlayingTask.value,
            connections: await connectionsTask.value,
            date: Date()
        )

        updateCache(with: snapshot)
        Logger.debug("Snapshot read completed", category: .sensors)
        try throwIfReadFailed(errors)

        return snapshot
    }

    /// Lit un snapshot sans lancer d'erreur (retourne les valeurs par défaut en cas d'échec)
    public func readSnapshotSafely() async -> Snapshot {
        do {
            return try await readSnapshot()
        } catch {
            Logger.error(error, category: .sensors)
            // Retourner le dernier snapshot valide ou un nouveau par défaut
            return lock.withLock({ lastSnapshot ?? Snapshot() })
        }
    }

    // MARK: - Private Methods

    /// Le snapshot en cache s'il est encore frais.
    private func cachedSnapshot() -> Snapshot? {
        lock.withLock {
            guard let cached = lastSnapshot,
                  Date().timeIntervalSince(lastReadTime) < minimumReadInterval else { return nil }
            return cached
        }
    }

    /// Remplace le cache par le snapshot qui vient d'être lu.
    private func updateCache(with snapshot: Snapshot) {
        lock.withLock {
            lastSnapshot = snapshot
            lastReadTime = Date()
        }
    }

    /// Lance une lecture avec retry comme tâche concurrente.
    private func retryTask<T>(
        _ read: @escaping @Sendable () async throws -> T,
        name: String
    ) -> Task<T, Error> {
        Task { try await readWithRetry(read, readerName: name) }
    }

    /// Attend une lecture et, si elle échoue, consigne le reader en échec
    /// et rend sa valeur par défaut : le snapshot reste utilisable.
    private func readOrDefault<T>(
        _ task: Task<T, Error>,
        name: String,
        fallback: T,
        errors: inout [String]
    ) async -> T {
        do {
            return try await task.value
        } catch {
            errors.append(name)
            Logger.error(error, category: .sensors)
            return fallback
        }
    }

    /// La température, ou la métrique vide si le reader est absent.
    private func readTemperature() async throws -> Temperature {
        guard let tempReader = temperatureReader else { return Temperature() }
        return try await readWithRetry({ try await tempReader.read() }, readerName: "Temperature")
    }

    /// Traduit les échecs collectés en erreur : tous les readers en échec,
    /// ou seulement certains. Le snapshot en cache reste utilisable via
    /// `readSnapshotSafely`.
    private func throwIfReadFailed(_ errors: [String]) throws {
        if errors.count == 7 {
            Logger.error(SnapshotError.allReadersFailed, category: .sensors)
            throw SnapshotError.allReadersFailed
        }
        if !errors.isEmpty {
            Logger.warning("Partial snapshot: {\((errors.joined(separator: ", ")))}", category: .sensors)
            throw SnapshotError.partialRead(failedReaders: errors)
        }
    }

    private func readWithRetry<T>(
        _ operation: @escaping () async throws -> T,
        readerName: String,
        attempt: Int = 1
    ) async throws -> T {
        do {
            return try await operation()
        } catch let error as ReaderError {
            // Si c'est une erreur récupérable, on retry
            if isRecoverableError(error), attempt < 3 {
                Logger.info(
                    "Retrying {\((readerName))} (attempt {\((attempt))}/3)",
                    category: .sensors
                )
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                return try await readWithRetry(operation, readerName: readerName, attempt: attempt + 1)
            } else {
                throw error
            }
        } catch {
            // Erreur inconnue, on retry
            Logger.error(error, category: .sensors)

            if attempt < 3 {
                Logger.info(
                    "Retrying {\((readerName))} (attempt {\((attempt))}/3)",
                    category: .sensors
                )
                try await Task.sleep(nanoseconds: 500_000_000)
                return try await readWithRetry(operation, readerName: readerName, attempt: attempt + 1)
            } else {
                throw error
            }
        }
    }

    private func isRecoverableError(_ error: ReaderError) -> Bool {
        switch error {
        case .timeout, .serviceNotAvailable:
            return true
        default:
            return false
        }
    }
}

// MARK: - Protocole SnapshotReaderProtocol

public protocol SnapshotReaderProtocol {
    func readSnapshot() async throws -> Snapshot
    func readSnapshotSafely() async -> Snapshot
}

// MARK: - Extension pour rendre SnapshotReader conforme au protocole

extension SnapshotReader: SnapshotReaderProtocol {}
