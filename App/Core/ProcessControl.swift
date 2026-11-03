//
//  ProcessControl.swift
//  HAL
//
//  Utilitaires pour contrôler les processus.
//

import Foundation
import Darwin

/// Contrôle des processus
public enum ProcessControl {

    /// Tue un processus avec le PID donné
    /// - Parameter pid: L'ID du processus à tuer
    /// - Returns: true si le processus a été tué avec succès
    public static func terminate(_ pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        return kill(pid, SIGTERM) == 0 || kill(pid, SIGKILL) == 0
    }

    /// Vérifie si un processus peut être tué
    /// - Parameter pid: L'ID du processus
    /// - Returns: true si le processus peut être tué
    public static func canTerminate(_ pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        // Vérifier si le processus existe encore
        return kill(pid, 0) == 0 || errno != ESRCH
    }
}
