//
//  DiskReaderTests.swift
//  HALTests
//
//  Tests unitaires pour DiskReader.
//

import XCTest
@testable import HAL

final class DiskReaderTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDiskReaderInitialization() async {
        do {
            let reader = try await DiskReader()
            XCTAssertNotNil(reader, "DiskReader should initialize")
        } catch {
            // Peut échouer si pas de disque détecté
        }
    }

    // MARK: - Read Tests

    func testDiskReaderRead() async {
        do {
            let reader = try await DiskReader()
            let usage = try await reader.read()

            // Vérifier les propriétés
            XCTAssertGreaterThanOrEqual(usage.used, 0, "Used space should be >= 0")
            XCTAssertGreaterThanOrEqual(usage.total, 0, "Total space should be >= 0")
            XCTAssertGreaterThanOrEqual(usage.free, 0, "Free space should be >= 0")

            // Vérifier que used + free <= total (en tenant compte des overheads)
            if usage.total > 0 {
                XCTAssertLessThanOrEqual(
                    usage.used + usage.free, usage.total * 1.1,
                    "Used + Free should be roughly <= Total")
            }

            XCTAssertTrue(usage.isPresent, "Disk should be present on most systems")
            XCTAssertFalse(usage.fileSystem.isEmpty, "File system should not be empty")
        } catch {
            // Ignorer si pas de disque
        }
    }

    func testDiskReaderFractionCalculation() {
        // Test direct de la propriété computed
        var usage = DiskUsage()

        // Cas normal
        usage.used = 200_000_000_000
        usage.total = 500_000_000_000
        XCTAssertEqual(usage.fraction, 0.4, accuracy: 0.001)

        // Cas où used = 0
        usage.used = 0
        usage.total = 500_000_000_000
        XCTAssertEqual(usage.fraction, 0, accuracy: 0.001)

        // Cas où total = 0 (division par zéro)
        usage.used = 200_000_000_000
        usage.total = 0
        XCTAssertEqual(usage.fraction, 0, accuracy: 0.001)
    }

    // MARK: - Mock Tests

    func testMockDiskReader() async {
        let mockReader = MockDiskReader(
            mockUsage: DiskUsage(
                isPresent: true,
                used: 200_000_000_000,
                total: 500_000_000_000,
                free: 300_000_000_000,
                fileSystem: "APFS"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertTrue(usage.isPresent)
            XCTAssertEqual(usage.used, 200_000_000_000)
            XCTAssertEqual(usage.total, 500_000_000_000)
            XCTAssertEqual(usage.free, 300_000_000_000)
            XCTAssertEqual(usage.fileSystem, "APFS")
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockDiskReaderNotPresent() async {
        let mockReader = MockDiskReader(
            mockUsage: DiskUsage(
                isPresent: false,
                used: 0,
                total: 0,
                free: 0,
                fileSystem: ""
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertFalse(usage.isPresent)
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockDiskReaderCallCount() async {
        let mockReader = MockDiskReader()

        XCTAssertEqual(mockReader.readCallCount, 0)

        do {
            _ = try await mockReader.read()
            XCTAssertEqual(mockReader.readCallCount, 1)

            _ = try await mockReader.read()
            XCTAssertEqual(mockReader.readCallCount, 2)
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockDiskReaderError() async {
        let mockReader = MockDiskReader()
        mockReader.shouldThrow = true

        do {
            _ = try await mockReader.read()
            XCTFail("Should have thrown an error")
        } catch {
            // Attendu
        }
    }

    // MARK: - Performance Tests

    func testDiskReaderPerformance() async {
        do {
            let reader = try await DiskReader()

            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.1, // 100ms
                "Disk read should complete in less than 100ms"
            )
        } catch {
            // Ignorer si pas de disque
        }
    }

    // MARK: - Edge Cases Tests

    func testZeroDiskSpace() async {
        let mockReader = MockDiskReader(
            mockUsage: DiskUsage(
                isPresent: true,
                used: 0,
                total: 0,
                free: 0,
                fileSystem: "APFS"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.used, 0)
            XCTAssertEqual(usage.total, 0)
            XCTAssertEqual(usage.free, 0)
        } catch {
            XCTFail("Should handle zero disk: {\((error))}")
        }
    }

    func testFullDisk() async {
        let mockReader = MockDiskReader(
            mockUsage: DiskUsage(
                isPresent: true,
                used: 500_000_000_000,
                total: 500_000_000_000,
                free: 0,
                fileSystem: "APFS"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.fraction, 1.0, accuracy: 0.001)
        } catch {
            XCTFail("Should handle full disk: {\((error))}")
        }
    }

    func testVeryLargeDisk() async {
        let mockReader = MockDiskReader(
            mockUsage: DiskUsage(
                isPresent: true,
                used: 1_000_000_000_000,
                total: 8_000_000_000_000, // 8TB
                free: 7_000_000_000_000,
                fileSystem: "APFS"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.total, 8_000_000_000_000)
        } catch {
            XCTFail("Should handle large disk: {\((error))}")
        }
    }

    // MARK: - DiskUsage Properties Tests

    func testDiskUsageDefaultInitializer() {
        let usage = DiskUsage()
        XCTAssertFalse(usage.isPresent)
        XCTAssertEqual(usage.used, 0)
        XCTAssertEqual(usage.total, 0)
        XCTAssertEqual(usage.free, 0)
        XCTAssertTrue(usage.fileSystem.isEmpty)
    }
}

// MARK: - Mock DiskReader

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
