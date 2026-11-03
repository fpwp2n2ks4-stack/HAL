//
//  Snapshot.swift
//  HAL
//
//  Modèle pour un instantané de toutes les métriques système.
//

import Foundation

/// Un instantané de toutes les métriques système à un moment donné
public struct Snapshot: Sendable {
    public var cpu: CPUUsage = CPUUsage()
    public var memory: MemoryUsage = MemoryUsage()
    public var network: NetworkUsage = NetworkUsage()
    public var disk: DiskUsage = DiskUsage()
    public var battery: BatteryStatus = BatteryStatus()
    public var gpu: GPUUsage = GPUUsage()
    public var temperature: Temperature = Temperature()
    public var processes: [ProcessUsage] = []
    public var bluetooth: [BluetoothDevice] = []
    public var nowPlaying: NowPlaying = NowPlaying()
    /// Connexions réseau, entrantes et sortantes, en cache.
    public var connections: [NetworkConnection] = []
    public var date: Date = Date()

    public init() {}

    public init(
        cpu: CPUUsage = CPUUsage(),
        memory: MemoryUsage = MemoryUsage(),
        network: NetworkUsage = NetworkUsage(),
        disk: DiskUsage = DiskUsage(),
        battery: BatteryStatus = BatteryStatus(),
        gpu: GPUUsage = GPUUsage(),
        temperature: Temperature = Temperature(),
        processes: [ProcessUsage] = [],
        bluetooth: [BluetoothDevice] = [],
        nowPlaying: NowPlaying = NowPlaying(),
        connections: [NetworkConnection] = [],
        date: Date = Date()
    ) {
        self.cpu = cpu
        self.memory = memory
        self.network = network
        self.disk = disk
        self.battery = battery
        self.gpu = gpu
        self.temperature = temperature
        self.processes = processes
        self.bluetooth = bluetooth
        self.nowPlaying = nowPlaying
        self.connections = connections
        self.date = date
    }
}
