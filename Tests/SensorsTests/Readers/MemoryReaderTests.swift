//
//  MemoryReaderTests.swift
//  HALTests
//
//  Tests unitaires pour MemoryReader.
//

import XCTest
@testable import HAL

final class MemoryReaderTests: XCTestCase {

    // MARK: - Read Tests

    func testMemoryReaderRead() async {
        let reader = MemoryReader()

        do {
            let usage = try await reader.read()

            // Vérifier que les valeurs sont positives
            XCTAssertGreaterThan(usage.used, 0, "Memory used should be > 0")
            XCTAssertGreaterThan(usage.total, 0, "Memory total should be > 0")

            // Vérifier que used <= total
            XCTAssertLessThanOrEqual(usage.used, usage.total, "Used memory should be <= total")

            // Vérifier que fraction est entre 0 et 1
            XCTAssertGreaterThanOrEqual(usage.fraction, 0, "Memory fraction should be >= 0")
            XCTAssertLessThanOrEqual(usage.fraction, 1, "Memory fraction should be <= 1")
        } catch {
            XCTFail("Memory read failed: {\((error))}")
        }
    }

    func testMemoryReaderFractionCalculation() {
        // Test direct de la propriété computed
        var usage = MemoryUsage()

        // Cas normal
        usage.used = 500_000_000
        usage.total = 1_000_000_000
        XCTAssertEqual(usage.fraction, 0.5, accuracy: 0.001)

        // Cas où used = 0
        usage.used = 0
        usage.total = 1_000_000_000
        XCTAssertEqual(usage.fraction, 0, accuracy: 0.001)

        // Cas où total = 0 (division par zéro)
        usage.used = 500_000_000
        usage.total = 0
        XCTAssertEqual(usage.fraction, 0, accuracy: 0.001)
    }

    func testMemoryReaderPerformance() async {
        let reader = MemoryReader()

        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.05, // 50ms
                "Memory read should complete in less than 50ms"
            )
        } catch {
            XCTFail("Performance test failed: {\((error))}")
        }
    }
}

// MARK: - Mock MemoryReader

class MockMemoryReader: MemoryReaderProtocol {
    var mockUsage: MemoryUsage
    var readCallCount = 0

    init(mockUsage: MemoryUsage = MemoryUsage(
        used: 4_000_000_000,
        total: 8_000_000_000,
        compressed: 500_000_000,
        wired: 1_000_000_000
    )) {
        self.mockUsage = mockUsage
    }

    func read() async throws -> MemoryUsage {
        readCallCount += 1
        return mockUsage
    }
}

protocol MemoryReaderProtocol {
    func read() async throws -> MemoryUsage
}

// Extension pour rendre MemoryReader conforme au protocole

extension MemoryReader: MemoryReaderProtocol {}
