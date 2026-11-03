//
//  GPUReaderTests.swift
//  HALTests
//
//  Tests unitaires pour GPUReader.
//

import XCTest
@testable import HAL

final class GPUReaderTests: XCTestCase {

    // MARK: - Initialization Tests

    func testGPUReaderInitialization() async {
        do {
            let reader = try await GPUReader()
            XCTAssertNotNil(reader, "GPUReader should initialize")
        } catch {
            // Peut échouer si pas de GPU ou service non disponible
        }
    }

    // MARK: - Read Tests

    func testGPUReaderRead() async {
        do {
            let reader = try await GPUReader()
            let usage = try await reader.read()

            // Vérifier que les valeurs sont dans les plages valides
            XCTAssertGreaterThanOrEqual(usage.deviceUtilization, 0, "GPU utilization should be >= 0%")
            XCTAssertLessThanOrEqual(usage.deviceUtilization, 100, "GPU utilization should be <= 100%")

            XCTAssertGreaterThanOrEqual(usage.inUseMemory, 0, "GPU memory should be >= 0")
        } catch {
            // Ignorer si pas de GPU détecté
        }
    }

    // MARK: - Mock Tests

    func testMockGPUReader() async {
        let mockReader = MockGPUReader(
            mockUsage: GPUUsage(
                deviceUtilization: 30,
                inUseMemory: 1_000_000_000
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.deviceUtilization, 30)
            XCTAssertEqual(usage.inUseMemory, 1_000_000_000)
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockGPUReaderCallCount() async {
        let mockReader = MockGPUReader()

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

    func testMockGPUReaderError() async {
        let mockReader = MockGPUReader()
        mockReader.shouldThrow = true

        do {
            _ = try await mockReader.read()
            XCTFail("Should have thrown an error")
        } catch {
            // Attendu
        }
    }

    // MARK: - Performance Tests

    func testGPUReaderPerformance() async {
        do {
            let reader = try await GPUReader()

            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.1, // 100ms
                "GPU read should complete in less than 100ms"
            )
        } catch {
            // Ignorer si pas de GPU
        }
    }

    // MARK: - Edge Cases Tests

    func testZeroGPUUtilization() async {
        let mockReader = MockGPUReader(
            mockUsage: GPUUsage(
                deviceUtilization: 0,
                inUseMemory: 0
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.deviceUtilization, 0)
            XCTAssertEqual(usage.inUseMemory, 0)
        } catch {
            XCTFail("Should handle 0% GPU: {\((error))}")
        }
    }

    func testFullGPUUtilization() async {
        let mockReader = MockGPUReader(
            mockUsage: GPUUsage(
                deviceUtilization: 100,
                inUseMemory: 8_000_000_000
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.deviceUtilization, 100)
            XCTAssertEqual(usage.inUseMemory, 8_000_000_000)
        } catch {
            XCTFail("Should handle 100% GPU: {\((error))}")
        }
    }

    func testLargeGPUMemory() async {
        let mockReader = MockGPUReader(
            mockUsage: GPUUsage(
                deviceUtilization: 50,
                inUseMemory: 16_000_000_000 // 16GB
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.inUseMemory, 16_000_000_000)
        } catch {
            XCTFail("Should handle large GPU memory: {\((error))}")
        }
    }

    // MARK: - GPUUsage Properties Tests

    func testGPUUsageDefaultInitializer() {
        let usage = GPUUsage()
        XCTAssertEqual(usage.deviceUtilization, 0)
        XCTAssertEqual(usage.inUseMemory, 0)
    }
}

// MARK: - Mock GPUReader

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
