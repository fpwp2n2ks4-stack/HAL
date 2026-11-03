//
//  SnapshotReaderTests.swift
//  HALTests
//
//  Tests unitaires pour SnapshotReader avec dependency injection.
//

import XCTest
@testable import HAL

final class SnapshotReaderTests: XCTestCase {

    // MARK: - Mock Setup

    private var mockCPUReader: MockCPUReader!
    private var mockMemoryReader: MockMemoryReader!
    private var mockNetworkReader: MockNetworkReader!
    private var mockBatteryReader: MockBatteryReader!
    private var mockTemperatureReader: MockTemperatureReader!
    private var mockGPUReader: MockGPUReader!
    private var mockDiskReader: MockDiskReader!
    private var snapshotReader: SnapshotReaderWithDI!

    override func setUp() {
        super.setUp()
        makeUsageMocks()
        makeEnvironmentMocks()
        makeSnapshotReader()
    }

    /// Les quatre sondes de charge : CPU, mémoire, réseau, batterie.
    private func makeUsageMocks() {
        mockCPUReader = MockCPUReader(
            mockUsage: CPUUsage(total: 50, perCore: [25, 25, 50, 50])
        )

        mockMemoryReader = MockMemoryReader(
            mockUsage: MemoryUsage(
                used: 4_000_000_000,
                total: 8_000_000_000,
                compressed: 500_000_000,
                wired: 1_000_000_000
            )
        )

        mockNetworkReader = MockNetworkReader(
            mockUsage: NetworkUsage(
                downloadPerSecond: 1_000_000,
                uploadPerSecond: 500_000,
                activeInterface: "en0"
            )
        )

        mockBatteryReader = MockBatteryReader(
            mockStatus: BatteryStatus(
                level: 80,
                isCharging: true,
                isPlugged: true,
                isLowPowerMode: false,
                isPresent: true
            )
        )
    }

    /// Les sondes d'environnement : température, GPU, disque.
    private func makeEnvironmentMocks() {
        mockTemperatureReader = MockTemperatureReader(
            mockTemperature: Temperature(
                socAverage: 50.5,
                socPeak: 65.2,
                dieCount: 1
            )
        )

        mockGPUReader = MockGPUReader(
            mockUsage: GPUUsage(
                deviceUtilization: 30,
                inUseMemory: 1_000_000_000
            )
        )

        mockDiskReader = MockDiskReader(
            mockUsage: DiskUsage(
                isPresent: true,
                used: 200_000_000_000,
                total: 500_000_000_000,
                free: 300_000_000_000,
                fileSystem: "APFS"
            )
        )
    }

    /// Le lecteur de snapshots, assemblé à partir des mocks.
    private func makeSnapshotReader() {
        snapshotReader = SnapshotReaderWithDI(
            cpuReader: mockCPUReader,
            memoryReader: mockMemoryReader,
            networkReader: mockNetworkReader,
            batteryReader: mockBatteryReader,
            temperatureReader: mockTemperatureReader,
            gpuReader: mockGPUReader,
            diskReader: mockDiskReader
        )
    }

    override func tearDown() {
        mockCPUReader = nil
        mockMemoryReader = nil
        mockNetworkReader = nil
        mockBatteryReader = nil
        mockTemperatureReader = nil
        mockGPUReader = nil
        mockDiskReader = nil
        snapshotReader = nil
        super.tearDown()
    }

    // MARK: - Successful Read Tests

    func testReadSnapshotSuccessfully() async {
        do {
            let snapshot = try await snapshotReader.readSnapshot()

            // Vérifier les données CPU
            XCTAssertEqual(snapshot.cpu.total, 50)
            XCTAssertEqual(snapshot.cpu.perCore.count, 4)

            // Vérifier les données Memory
            XCTAssertEqual(snapshot.memory.used, 4_000_000_000)
            XCTAssertEqual(snapshot.memory.total, 8_000_000_000)

            // Vérifier les données Network
            XCTAssertEqual(snapshot.network.downloadPerSecond, 1_000_000)
            XCTAssertEqual(snapshot.network.uploadPerSecond, 500_000)

            // Vérifier les données Battery
            XCTAssertEqual(snapshot.battery.level, 80)
            XCTAssertTrue(snapshot.battery.isCharging)

            // Vérifier les données Temperature
            XCTAssertEqual(snapshot.temperature.socAverage, 50.5, accuracy: 0.1)
            XCTAssertEqual(snapshot.temperature.socPeak, 65.2, accuracy: 0.1)

            // Vérifier les données GPU
            XCTAssertEqual(snapshot.gpu.deviceUtilization, 30)

            // Vérifier les données Disk
            XCTAssertTrue(snapshot.disk.isPresent)
            XCTAssertEqual(snapshot.disk.used, 200_000_000_000)

            // Vérifier la date
            XCTAssertNotNil(snapshot.date)

        } catch {
            XCTFail("Read snapshot failed: {\((error))}")
        }
    }

    func testReadSnapshotSafely() async {
        let snapshot = await snapshotReader.readSnapshotSafely()

        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot.cpu.total, 50)
        XCTAssertEqual(snapshot.memory.used, 4_000_000_000)
    }

    // MARK: - Error Handling Tests

    func testReadSnapshotWithCPUError() async {
        mockCPUReader.shouldThrow = true

        do {
            let snapshot = try await snapshotReader.readSnapshot()
            // Si un reader échoue, les autres devraient quand même réussir
            XCTAssertNotNil(snapshot)
            // CPU devrait être la valeur par défaut (0)
            XCTAssertEqual(snapshot.cpu.total, 0)
            // Memory devrait être correcte
            XCTAssertEqual(snapshot.memory.used, 4_000_000_000)
        } catch {
            // Si tous les readers échouent, on devrait avoir une erreur
            // Mais ici seulement CPU échoue, donc pas d'erreur globale
            XCTFail("Should handle partial failure: {\((error))}")
        }
    }

    func testReadSnapshotWithAllErrors() async {
        mockCPUReader.shouldThrow = true
        mockMemoryReader.shouldThrow = true
        mockNetworkReader.shouldThrow = true
        mockBatteryReader.shouldThrow = true
        mockTemperatureReader.shouldThrow = true
        mockGPUReader.shouldThrow = true
        mockDiskReader.shouldThrow = true

        do {
            _ = try await snapshotReader.readSnapshot()
            XCTFail("Should throw error when all readers fail")
        } catch let error as SnapshotError {
            switch error {
            case .allReadersFailed:
                break // Attendu
            default:
                XCTFail("Wrong error type: {\((error))}")
            }
        } catch {
            XCTFail("Wrong error type: {\((error))}")
        }
    }

    func testReadSnapshotWithPartialErrors() async {
        mockCPUReader.shouldThrow = true
        mockTemperatureReader.shouldThrow = true

        do {
            let snapshot = try await snapshotReader.readSnapshot()
            XCTAssertNotNil(snapshot)
            // Les readers qui ont échoué devraient avoir des valeurs par défaut
            XCTAssertEqual(snapshot.cpu.total, 0)
            XCTAssertNil(snapshot.temperature.socPeak)
            // Les autres devraient être corrects
            XCTAssertEqual(snapshot.memory.used, 4_000_000_000)
        } catch {
            XCTFail("Should handle partial failures: {\((error))}")
        }
    }

    // MARK: - Read Call Count Tests

    func testReadSnapshotCallsAllReaders() async {
        do {
            _ = try await snapshotReader.readSnapshot()

            XCTAssertEqual(mockCPUReader.readCallCount, 1)
            XCTAssertEqual(mockMemoryReader.readCallCount, 1)
            XCTAssertEqual(mockNetworkReader.readCallCount, 1)
            XCTAssertEqual(mockBatteryReader.readCallCount, 1)
            XCTAssertEqual(mockTemperatureReader.readCallCount, 1)
            XCTAssertEqual(mockGPUReader.readCallCount, 1)
            XCTAssertEqual(mockDiskReader.readCallCount, 1)
        } catch {
            XCTFail("Read failed: {\((error))}")
        }
    }

    func testMultipleReadsIncrementCallCount() async {
        do {
            _ = try await snapshotReader.readSnapshot()
            _ = try await snapshotReader.readSnapshot()

            XCTAssertEqual(mockCPUReader.readCallCount, 2)
            XCTAssertEqual(mockMemoryReader.readCallCount, 2)
        } catch {
            XCTFail("Read failed: {\((error))}")
        }
    }

    // MARK: - Performance Tests

    func testReadSnapshotPerformance() async {
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await snapshotReader.readSnapshot()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.1, // 100ms
                "Snapshot read should complete in less than 100ms with mocks"
            )
        } catch {
            XCTFail("Performance test failed: {\((error))}")
        }
    }

    // MARK: - Snapshot Properties Tests

    func testSnapshotDefaultInitializer() {
        let snapshot = Snapshot()

        XCTAssertEqual(snapshot.cpu.total, 0)
        XCTAssertTrue(snapshot.cpu.perCore.isEmpty)

        XCTAssertEqual(snapshot.memory.used, 0)
        XCTAssertEqual(snapshot.memory.total, 0)

        XCTAssertEqual(snapshot.network.downloadPerSecond, 0)
        XCTAssertEqual(snapshot.network.uploadPerSecond, 0)

        XCTAssertEqual(snapshot.battery.level, 0)

        XCTAssertNil(snapshot.temperature.socAverage)
        XCTAssertNil(snapshot.temperature.socPeak)

        XCTAssertEqual(snapshot.gpu.deviceUtilization, 0)

        XCTAssertFalse(snapshot.disk.isPresent)

        XCTAssertTrue(snapshot.processes.isEmpty)
        XCTAssertTrue(snapshot.bluetooth.isEmpty)
        XCTAssertTrue(snapshot.connections.isEmpty)
    }

    // MARK: - Concurrent Read Tests

    func testConcurrentSnapshotReads() async {
        async let snapshot1 = snapshotReader.readSnapshotSafely()
        async let snapshot2 = snapshotReader.readSnapshotSafely()
        async let snapshot3 = snapshotReader.readSnapshotSafely()

        let snapshots = await (snapshot1, snapshot2, snapshot3)

        XCTAssertNotNil(snapshots.0)
        XCTAssertNotNil(snapshots.1)
        XCTAssertNotNil(snapshots.2)
    }
}
