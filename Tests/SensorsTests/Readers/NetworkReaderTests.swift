//
//  NetworkReaderTests.swift
//  HALTests
//
//  Tests unitaires pour NetworkReader.
//

import XCTest
@testable import HAL

final class NetworkReaderTests: XCTestCase {

    // MARK: - Read Tests

    func testNetworkReaderRead() async {
        let reader = NetworkReader()

        do {
            let usage = try await reader.read()

            // Vérifier que les valeurs sont non-négatives
            XCTAssertGreaterThanOrEqual(usage.downloadPerSecond, 0, "Download should be >= 0")
            XCTAssertGreaterThanOrEqual(usage.uploadPerSecond, 0, "Upload should be >= 0")

            // Vérifier que activeInterface n'est pas vide
            XCTAssertFalse(usage.activeInterface.isEmpty, "Active interface should not be empty")
        } catch {
            XCTFail("Network read failed: {\((error))}")
        }
    }

    func testNetworkReaderPerformance() async {
        let reader = NetworkReader()

        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.1, // 100ms
                "Network read should complete in less than 100ms"
            )
        } catch {
            XCTFail("Performance test failed: {\((error))}")
        }
    }

    // MARK: - Mock Tests

    func testMockNetworkReader() async {
        let mockReader = MockNetworkReader(
            mockUsage: NetworkUsage(
                downloadPerSecond: 1_000_000,
                uploadPerSecond: 500_000,
                activeInterface: "en0"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.downloadPerSecond, 1_000_000)
            XCTAssertEqual(usage.uploadPerSecond, 500_000)
            XCTAssertEqual(usage.activeInterface, "en0")
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockNetworkReaderCallCount() async {
        let mockReader = MockNetworkReader()

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

    func testMockNetworkReaderError() async {
        let mockReader = MockNetworkReader()
        mockReader.shouldThrow = true

        do {
            _ = try await mockReader.read()
            XCTFail("Should have thrown an error")
        } catch {
            // Attendu
        }
    }

    // MARK: - Edge Cases Tests

    func testZeroNetworkUsage() async {
        let mockReader = MockNetworkReader(
            mockUsage: NetworkUsage(
                downloadPerSecond: 0,
                uploadPerSecond: 0,
                activeInterface: "en0"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.downloadPerSecond, 0)
            XCTAssertEqual(usage.uploadPerSecond, 0)
        } catch {
            XCTFail("Should handle zero network: {\((error))}")
        }
    }

    func testHighNetworkUsage() async {
        let mockReader = MockNetworkReader(
            mockUsage: NetworkUsage(
                downloadPerSecond: 1_000_000_000, // 1GB/s
                uploadPerSecond: 500_000_000,   // 500MB/s
                activeInterface: "en0"
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertEqual(usage.downloadPerSecond, 1_000_000_000)
            XCTAssertEqual(usage.uploadPerSecond, 500_000_000)
        } catch {
            XCTFail("Should handle high network: {\((error))}")
        }
    }

    func testEmptyInterfaceName() async {
        let mockReader = MockNetworkReader(
            mockUsage: NetworkUsage(
                downloadPerSecond: 0,
                uploadPerSecond: 0,
                activeInterface: ""
            )
        )

        do {
            let usage = try await mockReader.read()
            XCTAssertTrue(usage.activeInterface.isEmpty)
        } catch {
            XCTFail("Should handle empty interface: {\((error))}")
        }
    }

    // MARK: - NetworkUsage Properties Tests

    func testNetworkUsageDefaultInitializer() {
        let usage = NetworkUsage()
        XCTAssertEqual(usage.downloadPerSecond, 0)
        XCTAssertEqual(usage.uploadPerSecond, 0)
        XCTAssertTrue(usage.activeInterface.isEmpty)
    }
}

// MARK: - Mock NetworkReader

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
