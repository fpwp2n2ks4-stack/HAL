//
//  BluetoothDevice.swift
//  HAL
//
//  Modèle pour un périphérique Bluetooth.
//

/// Niveau de charge attachée à un périphérique Bluetooth
public struct BluetoothComponent: Sendable {
    public var kind: String  // "battery" | "left" | "right" | "case"
    public var level: Int    // 0...100
    public var isCharging: Bool

    public init(kind: String, level: Int, isCharging: Bool = false) {
        self.kind = kind
        self.level = level
        self.isCharging = isCharging
    }
}

/// Périphérique Bluetooth
public struct BluetoothDevice: Sendable {
    public var name: String
    public var components: [BluetoothComponent]

    public init(name: String, components: [BluetoothComponent]) {
        self.name = name
        self.components = components
    }
}
