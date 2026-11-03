//
//  CPUReaderTests.swift
//  HALTests
//
//  Tests unitaires pour CPUReader.
//

import XCTest
@testable import HAL

final class CPUReaderTests: XCTestCase {

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        // Initialiser le reader
    }

    override func tearDown() {
        // Nettoyer
    }

    // MARK: - Initialization Tests

    func testCPUReaderInitialization() async {
        do {
            let reader = try await CPUReader()
            XCTAssertGreaterThan(reader.coreCount, 0, "CPUReader should detect at least one core")
            XCTAssertEqual(reader.coreCount, ProcessInfo.processInfo.processorCount)
        } catch {
            XCTFail("CPUReader initialization failed: {\((error))}")
        }
    }

    // MARK: - Read Tests

    func testCPUReaderRead() async {
        do {
            let reader = try await CPUReader()
            let usage = try await reader.read()

            // Vérifier que les valeurs sont dans les plages attendues
            XCTAssertGreaterThanOrEqual(usage.total, 0, "CPU usage should be >= 0%")
            XCTAssertLessThanOrEqual(usage.total, 100, "CPU usage should be <= 100%")

            // Vérifier que perCore a le bon nombre d'éléments
            XCTAssertEqual(usage.perCore.count, reader.coreCount, "perCore count should match coreCount")

            // Vérifier que chaque valeur perCore est valide
            for (index, coreUsage) in usage.perCore.enumerated() {
                XCTAssertGreaterThanOrEqual(
                    coreUsage,
                    0,
                    "Core {\((index))} usage should be >= 0%"
                )
                XCTAssertLessThanOrEqual(
                    coreUsage,
                    100,
                    "Core {\((index))} usage should be <= 100%"
                )
            }
        } catch {
            XCTFail("CPU read failed: {\((error))}")
        }
    }

    func testCPUReaderConsistency() async {
        do {
            let reader = try await CPUReader()

            // Lire plusieurs fois
            let usage1 = try await reader.read()
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            let usage2 = try await reader.read()

            // Les valeurs ne doivent pas être identiques (sauf si CPU idle à 0%)
            if usage1.total > 0 || usage2.total > 0 {
                // Si le CPU est utilisé, les valeurs doivent changer
                XCTAssertNotEqual(
                    usage1.total,
                    usage2.total,
                    accuracy: 0.1,
                    "CPU usage should change between readings"
                )
            }
        } catch {
            XCTFail("Consistency test failed: {\((error))}")
        }
    }

    // MARK: - Performance Tests

    func testCPUReaderPerformance() async {
        do {
            let reader = try await CPUReader()

            // Mesurer le temps d'exécution
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.1,
                "CPU read should complete in less than 100ms"
            )
        } catch {
            XCTFail("Performance test failed: {\((error))}")
        }
    }

    // MARK: - Error Handling Tests

    func testCPUReaderErrorRecovery() async {
        // Ce test vérifie que le reader peut récupérer d'une erreur
        // Difficile à tester sans mock, mais on peut vérifier que
        // plusieurs lectures consécutives ne crashent pas

        do {
            let reader = try await CPUReader()

            // Lire plusieurs fois de suite
            for _ in 0..<5 {
                _ = try await reader.read()
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        } catch {
            XCTFail("Error recovery test failed: {\((error))}")
        }
    }
}

// MARK: - Mock CPUReader for testing other components

class MockCPUReader: CPUReaderProtocol {
    var coreCount: Int = 4
    var mockUsage: CPUUsage
    var readCallCount = 0

    init(mockUsage: CPUUsage = CPUUsage(total: 50, perCore: [25, 25, 50, 50])) {
        self.mockUsage = mockUsage
    }

    func read() async throws -> CPUUsage {
        readCallCount += 1
        return mockUsage
    }
}

protocol CPUReaderProtocol {
    var coreCount: Int { get }
    func read() async throws -> CPUUsage
}

// Extension pour rendre CPUReader conforme au protocole
// (utile pour les tests avec dependency injection)

extension CPUReader: CPUReaderProtocol {}
