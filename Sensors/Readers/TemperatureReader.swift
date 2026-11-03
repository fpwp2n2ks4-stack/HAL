//
//  TemperatureReader.swift
//  HAL
//
//  Lecteur des températures du SoC (Apple Silicon).
//

import Foundation

/// Lecteur des températures du SoC
public final class TemperatureReader: @unchecked Sendable {

    // Types IOKit non exposés
    typealias HIDClient = CFTypeRef
    typealias HIDService = CFTypeRef
    typealias HIDEvent = CFTypeRef

    // Déclarations des fonctions IOKit
    @_silgen_name("IOHIDEventSystemClientCreate")
    private func hidClientCreate(_ allocator: CFAllocator?) -> Unmanaged<HIDClient>?

    // Retourne void côté IOKit : la valeur de retour ne peut pas être
    // vérifiée, c'est `hidClientCopyServices` qui échoue si le filtre est
    // rejeté.
    @_silgen_name("IOHIDEventSystemClientSetMatching")
    private func hidClientSetMatching(_ client: HIDClient, _ match: CFDictionary)

    @_silgen_name("IOHIDEventSystemClientCopyServices")
    private func hidClientCopyServices(_ client: HIDClient) -> Unmanaged<CFTypeRef>?

    @_silgen_name("IOHIDServiceClientCopyProperty")
    private func hidServiceCopyProperty(_ service: HIDService, _ key: CFString) -> Unmanaged<CFTypeRef>?

    @_silgen_name("IOHIDServiceClientCopyEvent")
    private func hidServiceCopyEvent(
        _ service: HIDService,
        _ type: Int64,
        _ options: Int32,
        _ timestamp: Int64
    ) -> Unmanaged<HIDEvent>?

    @_silgen_name("IOHIDEventGetFloatValue")
    private func hidEventFloatValue(_ event: HIDEvent, _ field: Int32) -> Double

    // Constantes
    private let kHIDEventTypeTemperature: Int64 = 15
    private let kHIDEventFieldTemperatureBase: Int32 = 15 << 16

    // Références aux services
    private var client: Unmanaged<HIDClient>?
    private var servicesArray: Unmanaged<CFTypeRef>?
    private var matchedIndices: [Int] = []

    // MARK: - Lifecycle

    /// Initialise le lecteur de température
    public init() throws {
        try discover()
    }

    deinit {
        releaseResources()
    }

    // MARK: - Public Methods

    /// Lit les températures actuelles
    /// - Returns: Temperature avec les valeurs moyenne et maximale
    public func read() async throws -> Temperature {
        guard !matchedIndices.isEmpty else {
            throw ReaderError.unsupportedHardware
        }

        guard let array = servicesArray?.takeUnretainedValue() as? NSArray else {
            throw ReaderError.serviceNotAvailable
        }

        let timestamp = Date().timeIntervalSince1970 * 1_000_000_000
        var temperatures: [Double] = []
        var peak: Double = 0

        for index in matchedIndices {
            let service = array[index] as CFTypeRef
            guard let ownedEvent = hidServiceCopyEvent(
                service,
                kHIDEventTypeTemperature,
                0,
                Int64(timestamp)
            ) else {
                continue
            }

            let event = ownedEvent.takeUnretainedValue()
            let value = hidEventFloatValue(event, kHIDEventFieldTemperatureBase)
            temperatures.append(value)
            peak = max(peak, value)
        }

        if temperatures.isEmpty {
            throw ReaderError.invalidData(reason: "No temperature values received")
        }

        return Temperature(
            socAverage: temperatures.reduce(0, +) / Double(temperatures.count),
            socPeak: peak,
            dieCount: matchedIndices.count
        )
    }

    // MARK: - Private Methods

    /// Découvre les services de température
    private func discover() throws {
        releaseResources()

        guard let owned = hidClientCreate(kCFAllocatorDefault) else {
            throw ReaderError.serviceNotAvailable
        }
        client = owned
        let raw = owned.takeUnretainedValue()

        let match: NSDictionary = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 0x0005]
        hidClientSetMatching(raw, match as CFDictionary)

        guard let ownedArray = hidClientCopyServices(raw) else {
            releaseResources()
            throw ReaderError.serviceNotAvailable
        }
        servicesArray = ownedArray

        guard let array = ownedArray.takeUnretainedValue() as? NSArray else {
            releaseResources()
            throw ReaderError.invalidData(reason: "Invalid services array")
        }

        var foundIndices: [Int] = []
        for index in 0..<array.count {
            let service = array[index] as CFTypeRef
            guard let owned = hidServiceCopyProperty(service, "Product" as CFString) else {
                continue
            }
            let name = owned.takeRetainedValue() as? String
            guard let name, name.hasPrefix("PMU"), name.contains("tdie") else {
                continue
            }
            foundIndices.append(index)
        }

        guard !foundIndices.isEmpty else {
            releaseResources()
            throw ReaderError.unsupportedHardware
        }

        matchedIndices = foundIndices
    }

    /// Libère les ressources
    private func releaseResources() {
        servicesArray?.release()
        servicesArray = nil
        client?.release()
        client = nil
        matchedIndices = []
    }
}
