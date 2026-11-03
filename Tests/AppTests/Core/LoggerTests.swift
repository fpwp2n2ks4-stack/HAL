//
//  LoggerTests.swift
//  HALTests
//
//  Tests unitaires pour le système de Logger.
//

import XCTest
import os.log
@testable import HAL

final class LoggerTests: XCTestCase {

    // MARK: - Test Setup

    override func setUp() {
        super.setUp()
        // Réinitialiser les niveaux de log avant chaque test
        Logger.setLogLevel(.debug, for: .sensors)
        Logger.setLogLevel(.debug, for: .networking)
        Logger.setLogLevel(.debug, for: .display)
        Logger.setLogLevel(.debug, for: .lifecycle)
        Logger.setLogLevel(.debug, for: .performance)
    }

    // MARK: - LogLevel Tests

    func testLogLevelComparison() {
        // Test l'ordre des niveaux de log
        XCTAssertTrue(LogLevel.debug < .info)
        XCTAssertTrue(LogLevel.info < .warning)
        XCTAssertTrue(LogLevel.warning < .error)
        XCTAssertTrue(LogLevel.error < .fault)

        // Test l'égalité
        XCTAssertEqual(LogLevel.debug, LogLevel.debug)
        XCTAssertNotEqual(LogLevel.debug, LogLevel.info)
    }

    func testLogLevelOSLogTypeMapping() {
        XCTAssertEqual(LogLevel.debug.osLogType, OSLogType.debug)
        XCTAssertEqual(LogLevel.info.osLogType, OSLogType.info)
        XCTAssertEqual(LogLevel.warning.osLogType, OSLogType.default)
        XCTAssertEqual(LogLevel.error.osLogType, OSLogType.error)
        XCTAssertEqual(LogLevel.fault.osLogType, OSLogType.fault)
    }

    // MARK: - Logger Configuration Tests

    func testSetLogLevel() async {
        // Attendre que la configuration soit appliquée
        await Logger.setLogLevel(.warning, for: .sensors)

        // On ne peut pas vérifier directement la valeur dans l'acteur,
        // mais on peut vérifier que le set ne crash pas
        // et que les logs suivants respectent le niveau
    }

    func testEnableDisableLogging() async {
        await Logger.enableLogging(false, for: .sensors)
        // Devrait désactiver le logging pour sensors

        await Logger.enableLogging(true, for: .sensors)
        // Devrait réactiver le logging pour sensors
    }

    // MARK: - Logging Methods Tests

    func testDebugLog() {
        // Test que le debug log ne crash pas
        Logger.debug("Test debug message", category: .sensors)
    }

    func testInfoLog() {
        Logger.info("Test info message", category: .display)
    }

    func testWarningLog() {
        Logger.warning("Test warning message", category: .networking)
    }

    func testErrorLog() {
        let testError = NSError(domain: "Test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        Logger.error(testError, category: .lifecycle)
    }

    func testFaultLog() {
        Logger.fault("Test fault message", category: .performance)
    }

    func testLogWithAllParameters() {
        Logger.log(
            "Test message",
            level: .info,
            category: .sensors,
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: - Error Handling Tests

    func testErrorWithLocalizedError() {
        struct TestLocalizedError: LocalizedError {
            var errorDescription: String? = "Description"
            var recoverySuggestion: String? = "Suggestion"
        }

        let error = TestLocalizedError()
        Logger.error(error, category: .lifecycle)
    }

    func testErrorWithNonLocalizedError() {
        let error = NSError(domain: "Test", code: 456)
        Logger.error(error, category: .networking)
    }

    // MARK: - LogCategory Tests

    func testAllLogCategories() {
        let categories: [LogCategory] = [.sensors, .networking, .display, .lifecycle, .performance]

        for category in categories {
            Logger.debug("Testing {\((category.rawValue))}", category: category)
        }
    }

    // MARK: - String Formatting Tests

    func testLogMessageWithFormat() {
        let value = 42
        Logger.info("Value: %d", category: .sensors)
        Logger.info("Value: {\(value)", category: .sensors)
    }

    // MARK: - Concurrent Logging Tests

    func testConcurrentLogging() async {
        let dispatchGroup = DispatchGroup()

        for message in 0..<10 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                Logger.debug("Message {\(message)", category: .sensors)
                dispatchGroup.leave()
            }
        }

        await dispatchGroup.wait()
    }

    func testAsyncLogging() async {
        async let log1 = Logger.debug("Async message 1", category: .sensors)
        async let log2 = Logger.info("Async message 2", category: .display)
        async let log3 = Logger.warning("Async message 3", category: .networking)

        await (log1, log2, log3)
    }

    // MARK: - Performance Tests

    func testLoggingPerformance() {
        measure {
            for _ in 0..<100 {
                Logger.debug("Performance test message", category: .sensors)
            }
        }
    }

    // MARK: - Stress Tests

    func testHighVolumeLogging() {
        for message in 0..<1000 {
            Logger.debug("Stress test message {\(message)", category: .sensors)
        }
    }

    // MARK: - Edge Cases Tests

    func testEmptyMessage() {
        Logger.info("", category: .sensors)
    }

    func testVeryLongMessage() {
        let longMessage = String(repeating: "A", count: 10000)
        Logger.debug(longMessage, category: .sensors)
    }

    func testSpecialCharactersInMessage() {
        Logger.info("Test with special chars: \n\t\r\u{2028}", category: .sensors)
    }

    func testUnicodeInMessage() {
        Logger.info("Test with unicode: 你好世界 🌍", category: .sensors)
    }

    // MARK: - LoggerState Actor Tests

    func testLoggerStateIsolation() async {
        // Tester que les appels à LoggerState sont bien isolés
        async let level1 = LoggerState.sharedInstance().getLogLevel(for: .sensors)
        async let level2 = LoggerState.sharedInstance().getLogLevel(for: .display)

        _ = await (level1, level2)
        // Si pas de data race, le test passe
    }

    func testLoggerStateSetAndGet() async {
        let state = LoggerState.sharedInstance()

        await state.setLogLevel(.warning, for: .sensors)
        let level = await state.getLogLevel(for: .sensors)

        XCTAssertEqual(level, .warning)
    }

    func testLoggerStateOSLogCreation() async {
        let state = LoggerState.sharedInstance()

        let osLog1 = await state.getOrCreateOSLog(for: .sensors)
        let osLog2 = await state.getOrCreateOSLog(for: .sensors)

        // Devrait retourner le même OSLog
        XCTAssertTrue(osLog1 === osLog2)
    }

    func testLoggerStateDifferentCategoriesDifferentLogs() async {
        let state = LoggerState.sharedInstance()

        let osLog1 = await state.getOrCreateOSLog(for: .sensors)
        let osLog2 = await state.getOrCreateOSLog(for: .display)

        // Devrait retourner des OSLog différents
        XCTAssertFalse(osLog1 === osLog2)
    }

    // MARK: - Sendable Conformance Tests

    func testLogLevelIsSendable() {
        let level: LogLevel = .debug
        let _: any Sendable = level
    }

    func testLogCategoryIsSendable() {
        let category: LogCategory = .sensors
        let _: any Sendable = category
    }
}

// MARK: - Mock Logger for Testing Other Components

/// Mock Logger pour tester les composants qui utilisent Logger
class MockLogger: @unchecked Sendable {
    struct LogEntry {
        let message: String
        let level: LogLevel
        let category: LogCategory
        let file: String
        let function: String
        let line: Int
    }

    private(set) var entries: [LogEntry] = []
    private let queue = DispatchQueue(label: "com.hal.tests.MockLogger", attributes: .concurrent)

    var logCount: Int {
        queue.sync { entries.count }
    }

    var lastEntry: LogEntry? {
        queue.sync { entries.last }
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.entries.removeAll()
        }
    }

    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .lifecycle,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            message: message,
            level: level,
            category: category,
            file: file,
            function: function,
            line: line
        )

        queue.async(flags: .barrier) {
            self.entries.append(entry)
        }
    }

    func debug(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    func fault(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }

    func getEntries(for category: LogCategory) -> [LogEntry] {
        queue.sync { entries.filter { $0.category == category } }
    }

    func getEntries(withLevel level: LogLevel) -> [LogEntry] {
        queue.sync { entries.filter { $0.level == level } }
    }

    func hasLog(message: String, category: LogCategory? = nil, level: LogLevel? = nil) -> Bool {
        queue.sync {
            entries.contains { entry in
                entry.message.contains(message) &&
                (category == nil || entry.category == category) &&
                (level == nil || entry.level == level)
            }
        }
    }
}
