//
//  MemoryReader.swift
//  HAL
//
//  Lecteur de l'utilisation de la mémoire.
//

import Foundation

/// Lecteur de l'utilisation de la mémoire
public struct MemoryReader: Sendable {

    public init() {}

    /// Lit l'utilisation actuelle de la mémoire
    /// - Returns: MemoryUsage avec les valeurs utilisées, totale, compressée et wired
    public func read() async throws -> MemoryUsage {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let kernelStatus = host_statistics64(
            mach_host_self(),
            HOST_VM_INFO64,
            withUnsafeMutablePointer(to: &stats) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { $0 }
            },
            &count
        )

        guard kernelStatus == KERN_SUCCESS else {
            throw ReaderError.systemCallFailed(code: kernelStatus, function: "host_statistics64")
        }

        // Page size standard sur macOS (4096 octets)
        // Utilisation d'une constante car vm_page_size n'est pas thread-safe
        let pageSize = 4096.0
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize

        return MemoryUsage(
            used: active + wired + compressed,
            total: Double(ProcessInfo.processInfo.physicalMemory),
            compressed: compressed,
            wired: wired
        )
    }
}
