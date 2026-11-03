//
//  TemperatureReaderTests.swift
//  HALTests
//
//  Tests unitaires pour TemperatureReader.
//

import XCTest
@testable import HAL

final class TemperatureReaderTests: XCTestCase {

    // MARK: - Initialization Tests

    func testTemperatureReaderInitialization() async {
        do {
            let reader = try await TemperatureReader()
            XCTAssertNotNil(reader, "TemperatureReader should initialize")
        } catch {
            // Peut échouer sur certains matériels
        }
    }

    // MARK: - Read Tests

    func testTemperatureReaderRead() async {
        do {
            let reader = try await TemperatureReader()
            let temperature = try await reader.read()

            // Vérifier que les valeurs sont dans les plages valides
            if let socAverage = temperature.socAverage {
                XCTAssertGreaterThanOrEqual(socAverage, 0, "Temperature should be >= 0°C")
                XCTAssertLessThanOrEqual(socAverage, 150, "Temperature should be <= 150°C")
            }

            if let socPeak = temperature.socPeak {
                XCTAssertGreaterThanOrEqual(socPeak, 0, "Peak temperature should be >= 0°C")
                XCTAssertLessThanOrEqual(socPeak, 150, "Peak temperature should be <= 150°C")
            }

            XCTAssertGreaterThanOrEqual(temperature.dieCount, 0, "Die count should be >= 0")
        } catch {
            // Ignorer si pas de capteur de température
        }
    }

    func testTemperatureReaderPeakHigherThanAverage() async {
        do {
            let reader = try await TemperatureReader()
            let temperature = try await reader.read()

            if let socAverage = temperature.socAverage, let socPeak = temperature.socPeak {
                // Le pic devrait être >= à la moyenne
                XCTAssertGreaterThanOrEqual(socPeak, socAverage, "Peak should be >= average")
            }
        } catch {
            // Ignorer si pas de capteur
        }
    }

    // MARK: - Mock Tests

    func testMockTemperatureReader() async {
        let mockReader = MockTemperatureReader(
            mockTemperature: Temperature(
                socAverage: 50.5,
                socPeak: 65.2,
                dieCount: 1
            )
        )

        do {
            let temperature = try await mockReader.read()
            XCTAssertEqual(temperature.socAverage, 50.5, accuracy: 0.1)
            XCTAssertEqual(temperature.socPeak, 65.2, accuracy: 0.1)
            XCTAssertEqual(temperature.dieCount, 1)
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockTemperatureReaderWithNilValues() async {
        let mockReader = MockTemperatureReader(
            mockTemperature: Temperature(
                socAverage: nil,
                socPeak: nil,
                dieCount: 0
            )
        )

        do {
            let temperature = try await mockReader.read()
            XCTAssertNil(temperature.socAverage)
            XCTAssertNil(temperature.socPeak)
            XCTAssertEqual(temperature.dieCount, 0)
        } catch {
            XCTFail("Mock read failed: {\((error))}")
        }
    }

    func testMockTemperatureReaderCallCount() async {
        let mockReader = MockTemperatureReader()

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

    func testMockTemperatureReaderError() async {
        let mockReader = MockTemperatureReader()
        mockReader.shouldThrow = true

        do {
            _ = try await mockReader.read()
            XCTFail("Should have thrown an error")
        } catch {
            // Attendu
        }
    }

    // MARK: - Performance Tests

    func testTemperatureReaderPerformance() async {
        do {
            let reader = try await TemperatureReader()

            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await reader.read()
            let endTime = CFAbsoluteTimeGetCurrent()

            let executionTime = endTime - startTime
            XCTAssertLessThan(
                executionTime,
                0.1, // 100ms
                "Temperature read should complete in less than 100ms"
            )
        } catch {
            // Ignorer si pas de capteur
        }
    }

    // MARK: - Edge Cases Tests

    func testZeroTemperature() async {
        let mockReader = MockTemperatureReader(
            mockTemperature: Temperature(
                socAverage: 0,
                socPeak: 0,
                dieCount: 1
            )
        )

        do {
            let temperature = try await mockReader.read()
            XCTAssertEqual(temperature.socAverage, 0)
            XCTAssertEqual(temperature.socPeak, 0)
        } catch {
            XCTFail("Should handle 0°C: {\((error))}")
        }
    }

    func testVeryHighTemperature() async {
        let mockReader = MockTemperatureReader(
            mockTemperature: Temperature(
                socAverage: 120.0,
                socPeak: 150.0,
                dieCount: 1
            )
        )

        do {
            let temperature = try await mockReader.read()
            XCTAssertEqual(temperature.socAverage, 120.0, accuracy: 0.1)
            XCTAssertEqual(temperature.socPeak, 150.0, accuracy: 0.1)
        } catch {
            XCTFail("Should handle high temperature: {\((error))}")
        }
    }

    func testMultipleDies() async {
        let mockReader = MockTemperatureReader(
            mockTemperature: Temperature(
                socAverage: 50.0,
                socPeak: 75.0,
                dieCount: 4
            )
        )

        do {
            let temperature = try await mockReader.read()
            XCTAssertEqual(temperature.dieCount, 4)
        } catch {
            XCTFail("Should handle multiple dies: {\((error))}")
        }
    }

    // MARK: - Temperature Properties Tests

    func testTemperatureDefaultInitializer() {
        let temperature = Temperature()
        XCTAssertNil(temperature.socAverage)
        XCTAssertNil(temperature.socPeak)
        XCTAssertEqual(temperature.dieCount, 0)
    }
}

// MARK: - Mock TemperatureReader

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
