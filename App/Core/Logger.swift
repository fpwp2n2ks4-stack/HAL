//
//  Logger.swift
//  HAL
//
//  Système de logging centralisé.
//

import Foundation
import os.log

/// Niveaux de log
public enum LogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
    case fault

    public var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .fault: return .fault
        }
    }
}

// Conformance manuelle à Comparable
extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        // Ordre : debug < info < warning < error < fault
        let order: [LogLevel] = [.debug, .info, .warning, .error, .fault]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

/// Catégories de log
public enum LogCategory: String, Sendable {
    case sensors
    case networking
    case display
    case lifecycle
    case performance
}

/// Acteur interne pour la synchronisation thread-safe des propriétés de logging
private final actor LoggerState {
    let subsystem = "com.hal.app"
    var logLevels: [LogCategory: LogLevel] = [
        .sensors: .debug,
        .networking: .debug,
        .display: .info,
        .lifecycle: .info,
        .performance: .debug
    ]
    var logs: [LogCategory: OSLog] = [:]

    func getLogLevel(for category: LogCategory) -> LogLevel? {
        return logLevels[category]
    }

    func setLogLevel(_ level: LogLevel, for category: LogCategory) {
        logLevels[category] = level
    }

    func enableLogging(_ enabled: Bool, for category: LogCategory) {
        logLevels[category] = enabled ? .debug : .fault
    }

    func getOrCreateOSLog(for category: LogCategory) -> OSLog {
        if let existing = logs[category] {
            return existing
        }
        let newLog = OSLog(subsystem: subsystem, category: category.rawValue)
        logs[category] = newLog
        return newLog
    }

    private static let shared = LoggerState()
    static func sharedInstance() -> LoggerState { shared }
}

/// Logger centralisé - Thread-safe via acteur Swift
public enum Logger {

    // MARK: - Configuration

    /// Configure le niveau de log pour une catégorie
    public static func setLogLevel(_ level: LogLevel, for category: LogCategory) {
        Task {
            await LoggerState.sharedInstance().setLogLevel(level, for: category)
        }
    }

    /// Active/désactive le logging pour une catégorie
    public static func enableLogging(_ enabled: Bool, for category: LogCategory) {
        Task {
            await LoggerState.sharedInstance().enableLogging(enabled, for: category)
        }
    }

    // MARK: - Logging Methods

    /// Log un message
    public static func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task {
            let state = LoggerState.sharedInstance()
            // Vérifier si le niveau est suffisamment élevé
            guard let minLevel = await state.getLogLevel(for: category), level >= minLevel else {
                return
            }

            // Créer ou récupérer le logger OSLog
            let osLog = await state.getOrCreateOSLog(for: category)

            // Extraire le nom du fichier
            let fileName = URL(fileURLWithPath: file).lastPathComponent

            // Créer le message complet
            let fullMessage = "{\((fileName)):{\((line))} {\((function))} - {\((message))}"

            // Logger avec OSLog
            os_log(
                "%{",
                log: osLog,
                type: level.osLogType,
                fullMessage
            )

            // Also print to console in debug builds
            #if DEBUG
            let timestamp = Date().formatted(date: .omitted, time: .standard)
            let prefix = "[\((timestamp))] [{\((category.rawValue.uppercased()))}] [{\((level.rawValue.uppercased()))}]"
            print("{\((prefix))} {\((fullMessage))}")
            #endif
        }
    }

    // MARK: - Convenience Methods

    public static func debug(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    public static func info(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    public static func warning(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    public static func error(
        _ error: Error,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let message: String
        if let localizedError = error as? LocalizedError {
            message = localizedError.errorDescription ?? error.localizedDescription
        } else {
            message = error.localizedDescription
        }

        log(message, level: .error, category: category, file: file, function: function, line: line)

        // Log also the recovery suggestion if available
        if let localizedError = error as? LocalizedError,
           let suggestion = localizedError.recoverySuggestion {
            log("Suggestion: {\((suggestion))}", level: .info, category: category)
        }
    }

    public static func fault(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }
}
