//
//  GPUReader.swift
//  HAL
//
//  Lecteur de l'utilisation du GPU (Apple Silicon).
//

import Foundation

/// Lecteur de l'utilisation du GPU
public final class GPUReader: @unchecked Sendable {

    private var cached: GPUUsage = GPUUsage()

    public init() {}

    /// Lit l'utilisation actuelle du GPU
    /// - Returns: GPUUsage avec l'utilisation et la mémoire
    public func read() async throws -> GPUUsage {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOAccelerator"),
            &iterator
        ) == kIOReturnSuccess else {
            return cached
        }
        defer { IOObjectRelease(iterator) }

        var best: GPUUsage?
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }

            guard let stats = ioProperty(service, "PerformanceStatistics") as? [String: Any] else {
                continue
            }

            var usage = GPUUsage()
            usage.deviceUtilization = stats["Device Utilization %"] as? Int ?? 0
            usage.inUseMemory = Double(stats["In use system memory"] as? Int ?? 0)

            if best == nil || usage.deviceUtilization > best!.deviceUtilization {
                best = usage
            }
        }

        if let best {
            cached = best
        }
        return cached
    }

    // MARK: - Private Helpers

    private func ioProperty(_ service: io_object_t, _ key: String) -> AnyObject? {
        guard let ref = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return nil
        }
        return ref.takeRetainedValue()
    }
}
