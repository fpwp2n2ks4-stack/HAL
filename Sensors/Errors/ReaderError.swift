//
//  ReaderError.swift
//  HAL
//
//  Erreurs spécifiques aux lecteurs de métriques système.
//

import Foundation

/// Erreurs spécifiques aux lecteurs de métriques système
public enum ReaderError: Error, LocalizedError, Equatable {

    /// Échec d'un appel système
    case systemCallFailed(code: Int32, function: String)

    /// Données invalides reçues
    case invalidData(reason: String)

    /// Timeout de l'opération
    case timeout

    /// Permission refusée
    case permissionDenied

    /// Matériel non supporté
    case unsupportedHardware

    /// Service système non disponible
    case serviceNotAvailable

    /// Échec du parsing
    case parsingFailed(input: String)

    /// Commande non trouvée
    case commandNotFound(path: String)

    /// Commande échouée
    case commandFailed(status: Int32)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .systemCallFailed(let code, let function):
            return "System call '{\((function))}' failed with code {\((code))}"

        case .invalidData(let reason):
            return "Invalid data received: {\((reason))}"

        case .timeout:
            return "Operation timed out"

        case .permissionDenied:
            return "Permission denied - check accessibility settings"

        case .unsupportedHardware:
            return "Hardware not supported"

        case .serviceNotAvailable:
            return "System service not available"

        case .parsingFailed(let input):
            return "Failed to parse: {\((input.prefix(50)))...}"

        case .commandNotFound(let path):
            return "Command not found: {\((path))}"

        case .commandFailed(let status):
            return "Command failed with status: {\((status))}"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to System Settings > Privacy & Security to grant permissions"

        case .unsupportedHardware:
            return "This feature requires Apple Silicon (M1/M2/M3)"

        case .commandNotFound:
            return "Ensure the required system utilities are installed"

        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ReaderError, rhs: ReaderError) -> Bool {
        switch (lhs, rhs) {
        case (.systemCallFailed(let lhsCode, let lhsFunc), .systemCallFailed(let rhsCode, let rhsFunc)):
            return lhsCode == rhsCode && lhsFunc == rhsFunc

        case (.invalidData(let lhsReason), .invalidData(let rhsReason)):
            return lhsReason == rhsReason

        case (.timeout, .timeout):
            return true

        case (.permissionDenied, .permissionDenied):
            return true

        case (.unsupportedHardware, .unsupportedHardware):
            return true

        case (.serviceNotAvailable, .serviceNotAvailable):
            return true

        case (.parsingFailed(let lhsInput), .parsingFailed(let rhsInput)):
            return lhsInput == rhsInput

        case (.commandNotFound(let lhsPath), .commandNotFound(let rhsPath)):
            return lhsPath == rhsPath

        case (.commandFailed(let lhsStatus), .commandFailed(let rhsStatus)):
            return lhsStatus == rhsStatus

        default:
            return false
        }
    }
}
