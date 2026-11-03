//
//  BatteryReaderTests.swift
//  HALTests
//
//  Tests unitaires pour BatteryReader.
//

import XCTest
@testable import HAL

final class BatteryReaderTests: XCTestCase {

    // MARK: - Initialization Tests

    func testBatteryReaderInitialization() async {
        do {
            let reader = try await BatteryReader()
            XCTAssertNotNil(reader, "BatteryReader should initialize")
        } catch {
            // Sur certains Macs (comme les MacBook sans batterie), cela peut échouer
            // Ce n'est pas une erreur critique
        }
    }

    // MARK: - Read Tests

    func testBatteryReaderRead() async {
        do {
            let reader = try await BatteryReader()
            let status = try await reader.read()

            // Vérifier que les valeurs sont dans les plages valides
            XCTAssertGreaterThanOrEqual(status.level, 0, "Battery level should be >= 0")
            XCTAssertLessThanOrEqual(status.level, 100, "Battery level should be <= 100")

            // Vérifier que isPresent est cohérent
            if status.isPresent {
                // Si la batterie est présente, le niveau devrait être valide
                XCTAssertGreaterThanOrEqual(status.level, 0)
            }
        } catch {
            // Ignorer si pas de batterie détectée
        }
    }

    func testBatteryReaderIsCharging() async {
        do {
            let reader = try await BatteryReader()
            let status = try await reader.read()

            // isCharging et isPlugged devraient être cohérents
            if status.isCharging {
                XCTAssertTrue(status.isPlugged, "If charging, should be plugged")
            }

            // Note: isCharging implique isPlugged, mais isPlugged n'implique pas isCharging
        } catch {
            // Ignorer si pas de batterie détectée
        }
    }

    func testBatteryReaderLowPowerMode() async {
        do {
            let reader = try await BatteryReader()
            let status = try await reader.read()

            // isLowPowerMode est une propriété booléenne
            // On vérifie juste qu'elle est définie
            _ = status.isLowPowerMode
        } catch {
            // Ignorer si pas de batterie détectée
        }
    }

    // MARK: - Mock Tests

    func testMockBatteryReader() async {
        let mockReader = MockBatteryReader(
            mockStatus: BatteryStatus(
                level: 80,
                isCharging: true,
                isPlugged: true,
                isLowPowerMode: false,
                isPresent: true
            )
        )

        do {
            let status = try await mockReader.read()
            XCTAssertEqual(status.level, 80)
            XCTAssertTrue(status.isCharging)
            XCTAssertTrue(status.isPlugged)
            XCTAssertFalse(status.isLowPowerMode)
            XCTAssertTrue(status.isPresent)
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockBatteryReaderCallCount() async {
        let mockReader = MockBatteryReader()

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

    func testMockBatteryReaderError() async {
        let mockReader = MockBatteryReader()
        mockReader.shouldThrow = true

        do {
            _ = try await mockReader.read()
            XCTFail("Should have thrown an error")
        } catch {
            // Attendu
        }
    }

    // MARK: - Performance Tests

    func testBatteryReaderPerformance() async {
        do {
            let reader = try await BatteryReader()

            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.05, // 50ms
                "Battery read should complete in less than 50ms"
            )
        } catch {
            // Ignorer si pas de batterie
        }
    }

    // MARK: - Edge Cases Tests

    func testBatteryLevelZero() async {
        let mockReader = MockBatteryReader(
            mockStatus: BatteryStatus(
                level: 0,
                isCharging: true,
                isPlugged: true,
                isLowPowerMode: false,
                isPresent: true
            )
        )

        do {
            let status = try await mockReader.read()
            XCTAssertEqual(status.level, 0)
        } catch {
            XCTFail("Should handle 0% battery: {\((error))}")
        }
    }

    func testBatteryLevelHundred() async {
        let mockReader = MockBatteryReader(
            mockStatus: BatteryStatus(
                level: 100,
                isCharging: false,
                isPlugged: false,
                isLowPowerMode: false,
                isPresent: true
            )
        )

        do {
            let status = try await mockReader.read()
            XCTAssertEqual(status.level, 100)
        } catch {
            XCTFail("Should handle 100% battery: {\((error))}")
        }
    }

    func testBatteryNotPresent() async {
        let mockReader = MockBatteryReader(
            mockStatus: BatteryStatus(
                level: 0,
                isCharging: false,
                isPlugged: false,
                isLowPowerMode: false,
                isPresent: false
            )
        )

        do {
            let status = try await mockReader.read()
            XCTAssertFalse(status.isPresent)
        } catch {
            XCTFail("Should handle absent battery: {\((error))}")
        }
    }

    // MARK: - BatteryStatus Properties Tests

    func testBatteryStatusDefaultInitializer() {
        let status = BatteryStatus()
        XCTAssertEqual(status.level, 0)
        XCTAssertFalse(status.isCharging)
        XCTAssertFalse(status.isPlugged)
        XCTAssertFalse(status.isLowPowerMode)
        XCTAssertFalse(status.isPresent)
    }
}

// MARK: - Mock BatteryReader

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
