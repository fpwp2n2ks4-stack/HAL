//
//  CPUReader.swift
//  HAL
//
//  Lecteur de l'utilisation du CPU (Apple Silicon et Intel).
//

import Foundation

/// Lecteur de l'utilisation du CPU
public final class CPUReader: @unchecked Sendable {

    /// Structure interne pour stocker les ticks CPU
    private struct Ticks: Sendable {
        var user: UInt32 = 0
        var system: UInt32 = 0
        var idle: UInt32 = 0
        var nice: UInt32 = 0
    }

    private var previous: [Ticks] = []
    public private(set) var coreCount: Int = 0

    // Constant pour hostProcessorInfo
    private static let kFlavorProcessorCPULoad = processor_flavor_t(2) // PROCESSOR_CPU_LOAD_INFO
    private static let kCPUTicksPerCore = 4 // CPU_STATE_MAX

    // Déclaration manuelle de hostProcessorInfo pour macOS 24+
    @_silgen_name("host_processor_info")
    private static func hostProcessorInfo(
        _ host: mach_port_t,
        _ flavor: processor_flavor_t,
        _ outProcessorCount: UnsafeMutablePointer<natural_t>?,
        _ outProcessorInfo: UnsafeMutablePointer<UnsafeMutablePointer<integer_t>?>?,
        _ outProcessorInfoCnt: UnsafeMutablePointer<mach_msg_type_number_t>?
    ) -> kern_return_t

    // MARK: - Initialization

    /// Initialise le lecteur CPU
    public init() async {
        let ticks = await Self.sample()
        if !ticks.isEmpty {
            previous = ticks
            coreCount = ticks.count
        } else {
            coreCount = ProcessInfo.processInfo.processorCount
        }
    }

    // MARK: - Public Methods

    /// Lit l'utilisation actuelle du CPU
    /// - Returns: CPUUsage avec la charge totale et par cœur
    public func read() async -> CPUUsage {
        let now = await Self.sample()
        guard !now.isEmpty else {
            return CPUUsage()
        }

        var perCore: [Double] = []
        perCore.reserveCapacity(now.count)
        var sum: Double = 0

        for (index, current) in now.enumerated() {
            let old = index < previous.count ? previous[index] : Ticks()
            let dUser = current.user &- old.user
            let dSystem = current.system &- old.system
            let dIdle = current.idle &- old.idle
            let dNice = current.nice &- old.nice
            let ticks = Double(dUser &+ dSystem &+ dIdle &+ dNice)
            let load = ticks > 0 ? Double(dUser &+ dSystem) / ticks * 100 : 0
            perCore.append(load)
            sum += load
        }

        previous = now
        return CPUUsage(total: sum / Double(now.count), perCore: perCore)
    }

    // MARK: - Private Methods

    /// Échantillonne les ticks CPU
    /// - Returns: Tableau de ticks pour chaque cœur, ou tableau vide en cas d'échec
    private static func sample() async -> [Ticks] {
        return await withCheckedContinuation { continuation in
            var nproc: natural_t = 0
            var info: UnsafeMutablePointer<integer_t>?
            var count: mach_msg_type_number_t = 0

            let kernelStatus = hostProcessorInfo(
                mach_host_self(),
                kFlavorProcessorCPULoad,
                &nproc,
                &info,
                &count
            )

            guard kernelStatus == KERN_SUCCESS else {
                continuation.resume(returning: [])
                return
            }

            guard let info, nproc > 0 else {
                continuation.resume(returning: [])
                return
            }

            var result: [Ticks] = []
            result.reserveCapacity(Int(nproc))

            for core in 0..<Int(nproc) {
                result.append(Ticks(
                    user: UInt32(bitPattern: info[core * kCPUTicksPerCore + 0]),
                    system: UInt32(bitPattern: info[core * kCPUTicksPerCore + 1]),
                    idle: UInt32(bitPattern: info[core * kCPUTicksPerCore + 2]),
                    nice: UInt32(bitPattern: info[core * kCPUTicksPerCore + 3])
                ))
            }

            // Libérer la mémoire allouée par le noyau
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(count) * UInt(MemoryLayout<integer_t>.size)
            )

            continuation.resume(returning: result)
        }
    }
}
