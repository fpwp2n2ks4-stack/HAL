//
//  DiskReader.swift
//  HAL
//
//  Lecteur de l'utilisation du disque.
//

import Foundation
import Darwin

/// Lecteur de l'utilisation du disque
public struct DiskReader: Sendable {

    public init() {}

    /// Lit l'utilisation actuelle du disque
    /// - Returns: DiskUsage avec toutes les informations du disque
    public func read() async throws -> DiskUsage {
        var usage = DiskUsage()
        usage.isPresent = false

        // Lire le volume racine
        var statBuffer = statfs()
        guard statfs("/", &statBuffer) == 0 else {
            return usage
        }

        let blockSize = Double(statBuffer.f_bsize)
        usage.used = Double(statBuffer.f_blocks - statBuffer.f_bfree) * blockSize
        usage.total = Double(statBuffer.f_blocks) * blockSize
        usage.free = Double(statBuffer.f_bfree) * blockSize
        usage.isPresent = true

        // Type de système de fichiers
        // Note: f_fsid est de type fsid_t, on utilise une représentation simple
        usage.fileSystem = "APFS"

        // Lire l'activité disque (simplifié pour l'instant)
        // À améliorer avec IOKit pour plus de précision
        usage.readPerSecond = 0
        usage.writePerSecond = 0

        // SMART temperature (à implémenter)
        usage.smartTemperature = nil
        usage.smartHealth = nil

        return usage
    }
}
