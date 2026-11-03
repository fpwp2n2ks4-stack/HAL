//
//  MockReaders.swift
//  HALTests
//
//  Mocks pour tous les readers, pour les tests unitaires.
//

import Foundation
@testable import HAL

// MARK: - CPU Reader Mock

class MockCPUReader: CPUReaderProtocol {
    public var coreCount: Int = 4
    public var mockUsage: CPUUsage
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockUsage: CPUUsage = CPUUsage(total: 50, perCore: [25, 25, 50, 50])) {
        self.mockUsage = mockUsage
    }

    public func read() async throws -> CPUUsage {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.systemCallFailed(code: -1, function: "mock_cpu_failure")
        }
        return mockUsage
    }
}

protocol CPUReaderProtocol {
    var coreCount: Int { get }
    func read() async throws -> CPUUsage
}

// MARK: - Memory Reader Mock

class MockMemoryReader: MemoryReaderProtocol {
    public var mockUsage: MemoryUsage
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockUsage: MemoryUsage = MemoryUsage(
        used: 4_000_000_000,
        total: 8_000_000_000,
        compressed: 500_000_000,
        wired: 1_000_000_000
    )) {
        self.mockUsage = mockUsage
    }

    public func read() async throws -> MemoryUsage {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.systemCallFailed(code: -1, function: "mock_memory_failure")
        }
        return mockUsage
    }
}

protocol MemoryReaderProtocol {
    func read() async throws -> MemoryUsage
}

// MARK: - Network Reader Mock

class MockNetworkReader: NetworkReaderProtocol {
    public var mockUsage: NetworkUsage
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockUsage: NetworkUsage = NetworkUsage(
        downloadPerSecond: 1_000_000,
        uploadPerSecond: 500_000,
        activeInterface: "en0"
    )) {
        self.mockUsage = mockUsage
    }

    public func read() async throws -> NetworkUsage {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.systemCallFailed(code: -1, function: "mock_network_failure")
        }
        return mockUsage
    }
}

protocol NetworkReaderProtocol {
    func read() async throws -> NetworkUsage
}

// MARK: - Battery Reader Mock

class MockBatteryReader: BatteryReaderProtocol {
    public var mockStatus: BatteryStatus
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockStatus: BatteryStatus = BatteryStatus(
        level: 80,
        isCharging: true,
        isPlugged: true,
        isLowPowerMode: false,
        isPresent: true
    )) {
        self.mockStatus = mockStatus
    }

    public func read() async throws -> BatteryStatus {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.systemCallFailed(code: -1, function: "mock_battery_failure")
        }
        return mockStatus
    }
}

protocol BatteryReaderProtocol {
    func read() async throws -> BatteryStatus
}

// MARK: - Temperature Reader Mock

class MockTemperatureReader: TemperatureReaderProtocol {
    public var mockTemperature: Temperature
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockTemperature: Temperature = Temperature(
        socAverage: 50.5,
        socPeak: 65.2,
        dieCount: 1
    )) {
        self.mockTemperature = mockTemperature
    }

    public func read() async throws -> Temperature {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.unsupportedHardware
        }
        return mockTemperature
    }
}

protocol TemperatureReaderProtocol {
    func read() async throws -> Temperature
}

// MARK: - GPU Reader Mock

class MockGPUReader: GPUReaderProtocol {
    public var mockUsage: GPUUsage
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockUsage: GPUUsage = GPUUsage(
        deviceUtilization: 30,
        inUseMemory: 1_000_000_000
    )) {
        self.mockUsage = mockUsage
    }

    public func read() async throws -> GPUUsage {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.serviceNotAvailable
        }
        return mockUsage
    }
}

protocol GPUReaderProtocol {
    func read() async throws -> GPUUsage
}

// MARK: - Disk Reader Mock

class MockDiskReader: DiskReaderProtocol {
    public var mockUsage: DiskUsage
    public var readCallCount = 0
    public var shouldThrow = false

    public init(mockUsage: DiskUsage = DiskUsage(
        isPresent: true,
        used: 200_000_000_000,
        total: 500_000_000_000,
        free: 300_000_000_000,
        fileSystem: "APFS"
    )) {
        self.mockUsage = mockUsage
    }

    public func read() async throws -> DiskUsage {
        readCallCount += 1
        if shouldThrow {
            throw ReaderError.systemCallFailed(code: -1, function: "mock_disk_failure")
        }
        return mockUsage
    }
}

protocol DiskReaderProtocol {
    func read() async throws -> DiskUsage
}

// MARK: - SnapshotReader avec dependency injection

class SnapshotReaderWithDI: SnapshotReaderProtocol {
    private let cpuReader: CPUReaderProtocol
    private let memoryReader: MemoryReaderProtocol
    private let networkReader: NetworkReaderProtocol
    private let batteryReader: BatteryReaderProtocol
    private let temperatureReader: TemperatureReaderProtocol
    private let gpuReader: GPUReaderProtocol
    private let diskReader: DiskReaderProtocol

    public init(
        cpuReader: CPUReaderProtocol,
        memoryReader: MemoryReaderProtocol,
        networkReader: NetworkReaderProtocol,
        batteryReader: BatteryReaderProtocol,
        temperatureReader: TemperatureReaderProtocol,
        gpuReader: GPUReaderProtocol,
        diskReader: DiskReaderProtocol
    ) {
        self.cpuReader = cpuReader
        self.memoryReader = memoryReader
        self.networkReader = networkReader
        self.batteryReader = batteryReader
        self.temperatureReader = temperatureReader
        self.gpuReader = gpuReader
        self.diskReader = diskReader
    }

    public func readSnapshot() async throws -> Snapshot {
        var errors: [String] = []

        async let cpuTask = readWithRetry(cpuReader.read(), readerName: "CPU")
        async let memoryTask = readWithRetry(memoryReader.read(), readerName: "Memory")
        async let networkTask = readWithRetry(networkReader.read(), readerName: "Network")
        async let batteryTask = readWithRetry(batteryReader.read(), readerName: "Battery")
        async let temperatureTask = readWithRetry(temperatureReader.read(), readerName: "Temperature")
        async let gpuTask = readWithRetry(gpuReader.read(), readerName: "GPU")
        async let diskTask = readWithRetry(diskReader.read(), readerName: "Disk")

        let cpu: CPUUsage
        let memory: MemoryUsage
        let network: NetworkUsage
        let battery: BatteryStatus
        let temperature: Temperature
        let gpu: GPUUsage
        let disk: DiskUsage

        do { cpu = try await cpuTask } catch { cpu = CPUUsage(); errors.append("CPU") }

        do { memory = try await memoryTask } catch { memory = MemoryUsage(); errors.append("Memory") }

        do { network = try await networkTask } catch { network = NetworkUsage(); errors.append("Network") }

        do { battery = try await batteryTask } catch { battery = BatteryStatus(); errors.append("Battery") }

        do {
            temperature = try await temperatureTask
        } catch {
            temperature = Temperature()
            errors.append("Temperature")
        }

        do { gpu = try await gpuTask } catch { gpu = GPUUsage(); errors.append("GPU") }

        do { disk = try await diskTask } catch { disk = DiskUsage(); errors.append("Disk") }

        if errors.count == 7 {
            throw SnapshotError.allReadersFailed
        } else if !errors.isEmpty {
            throw SnapshotError.partialRead(failedReaders: errors)
        }

        return Snapshot(
            cpu: cpu,
            memory: memory,
            network: network,
            disk: disk,
            battery: battery,
            gpu: gpu,
            temperature: temperature,
            processes: [],
            bluetooth: [],
            nowPlaying: NowPlaying(),
            connections: [],
            date: Date()
        )
    }

    public func readSnapshotSafely() async -> Snapshot {
        do {
            return try await readSnapshot()
        } catch {
            print("Snapshot read error: {\((error))}")
            return Snapshot()
        }
    }

    // MARK: - Private Methods

    private func readWithRetry<T>(
        _ operation: @escaping () async throws -> T, readerName: String, attempt: Int = 1
    ) async throws -> T {
        do {
            return try await operation()
        } catch let error as ReaderError {
            if isRecoverableError(error), attempt < 3 {
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                return try await readWithRetry(operation, readerName: readerName, attempt: attempt + 1)
            } else {
                throw error
            }
        } catch {
            if attempt < 3 {
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

protocol SnapshotReaderProtocol {
    func readSnapshot() async throws -> Snapshot
    func readSnapshotSafely() async -> Snapshot
}

// Extensions pour rendre les readers réels conformes aux protocoles

extension CPUReader: CPUReaderProtocol {}
extension MemoryReader: MemoryReaderProtocol {}
extension NetworkReader: NetworkReaderProtocol {}
extension BatteryReader: BatteryReaderProtocol {}
extension TemperatureReader: TemperatureReaderProtocol {}
extension GPUReader: GPUReaderProtocol {}
extension DiskReader: DiskReaderProtocol {}
