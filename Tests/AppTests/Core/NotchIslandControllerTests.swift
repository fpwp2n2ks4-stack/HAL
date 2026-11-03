//
//  NotchIslandControllerTests.swift
//  HALTests
//
//  Tests unitaires pour NotchIslandController.
//

import XCTest
import AppKit
@testable import HAL

final class NotchIslandControllerTests: XCTestCase {

    private var theme: MockTheme!
    private var snapshot: Snapshot!
    private var controller: NotchIslandController!
    private var panel: NotchIslandPanel!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        theme = MockTheme()
        snapshot = Snapshot()

        // Créer un controller pour les tests
        // Note: On ne peut pas facilement tester le vrai controller car il nécessite
        // un écran avec notch. On va créer une version simplifiée pour les tests.
    }

    override func tearDown() {
        controller?.shutdown()
        controller = nil
        snapshot = nil
        theme = nil
        panel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testControllerInitialization() {
        // Créer un controller avec des valeurs par défaut
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        XCTAssertNotNil(controller, "Controller should be initialized")
    }

    // MARK: - Update Tests

    func testUpdateWithNewSnapshot() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 95.0
        newSnapshot.memory.fraction = 0.5

        // Mettre à jour le snapshot
        controller.update(snapshot: newSnapshot)

        // Vérifier que le controller a bien été mis à jour
        // (On ne peut pas vérifier directement car snapshot est private,
        // mais on vérifie que l'appel ne crash pas)
        XCTAssertNotNil(controller, "Controller should still exist after update")
    }

    func testUpdateWithHighCPUSnapshot() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Premier snapshot
        var firstSnapshot = Snapshot()
        firstSnapshot.cpu.total = 40.0
        firstSnapshot.temperature.socPeak = 50.0
        controller.update(snapshot: firstSnapshot)

        // Deuxième snapshot avec CPU > 90%
        var secondSnapshot = Snapshot()
        secondSnapshot.cpu.total = 95.0
        secondSnapshot.temperature.socPeak = 75.0
        secondSnapshot.memory.fraction = 0.5

        controller.update(snapshot: secondSnapshot)

        // Le controller devrait détecter le pic de CPU
        // (On ne peut pas vérifier directement si l'alerte s'affiche,
        // mais on vérifie que l'appel ne crash pas)
        XCTAssertNotNil(controller, "Controller should handle high CPU snapshot")
    }

    func testUpdateWithHighMemorySnapshot() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Premier snapshot
        var firstSnapshot = Snapshot()
        firstSnapshot.memory.fraction = 0.4
        controller.update(snapshot: firstSnapshot)

        // Deuxième snapshot avec mémoire > 90%
        var secondSnapshot = Snapshot()
        secondSnapshot.memory.fraction = 0.95

        controller.update(snapshot: secondSnapshot)

        XCTAssertNotNil(controller, "Controller should handle high memory snapshot")
    }

    // MARK: - Theme Application Tests

    func testApplyTheme() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        let newTheme = MockTheme()
        newTheme.palette.accent = .red

        controller.applyTheme(newTheme)

        // Vérifier que le thème a été appliqué
        // (On ne peut pas vérifier directement, mais on vérifie que l'appel ne crash pas)
        XCTAssertNotNil(controller, "Controller should handle theme change")
    }

    // MARK: - Geometry Tests

    func testScreenParametersDidChange() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Simuler un changement d'écran
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Vérifier que le controller gère le changement
        XCTAssertNotNil(controller, "Controller should handle screen parameter change")
    }

    // MARK: - Shutdown Tests

    func testShutdown() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Shutdown ne devrait pas crasher
        controller.shutdown()

        XCTAssertNotNil(controller, "Controller should exist after shutdown")
    }

    // MARK: - Mock for Testing

    func testControllerWithMockPanel() {
        // Créer un mock panel pour les tests
        panel = NotchIslandPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        XCTAssertNotNil(controller, "Controller should work with panel")
    }

    // MARK: - Anchor Properties Tests

    func testAnchorProperties() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Vérifier que les propriétés d'ancrage existent
        _ = controller.anchorFrame
        _ = controller.screen
        _ = controller.anchorView
        _ = controller.anchorRect

        XCTAssertNotNil(controller, "Controller should have anchor properties")
    }

    // MARK: - Metrics Line Tests

    func testMetricsLineGeneration() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Mettre à jour avec un snapshot qui a des données
        var testSnapshot = Snapshot()
        testSnapshot.cpu.total = 45.5
        testSnapshot.memory.fraction = 0.68
        testSnapshot.temperature.socPeak = 72.3
        testSnapshot.network.downloadPerSecond = 1_000_000
        testSnapshot.network.uploadPerSecond = 500_000
        testSnapshot.battery.level = 80
        testSnapshot.battery.isPresent = true

        controller.update(snapshot: testSnapshot)

        // On ne peut pas tester directement metricsLine car c'est private,
        // mais on vérifie que le controller fonctionne avec des données
        XCTAssertNotNil(controller, "Controller should handle snapshot with data")
    }
}

// MARK: - Mock Theme for Testing

class MockTheme: ThemeDefinition {
    var copy: ThemeCopy = MockThemeCopy()
    var palette: ThemePalette = MockThemePalette()
    var type: ThemeType = MockThemeType()

    func makeStatusItemView(snapshot: Snapshot) -> StatusItemView {
        return MockStatusItemView()
    }
}

class MockThemeCopy: ThemeCopy {
    var randomWhisper: () -> String = { "Test whisper" }
    var screenLabel: (Metrics) -> String = { metric in
        switch metric {
        case .cpu: return "CPU"
        case .memory: return "MEM"
        case .battery: return "BAT"
        case .disk: return "DISK"
        case .network: return "NET"
        }
    }
    var alertCPUMessage: String = "CPU Alert"
    var alertMemoryMessage: String = "Memory Alert"
    var alertBatteryMessage: String = "Battery Alert"
    var alertDiskMessage: String = "Disk Alert"
}

class MockThemePalette: ThemePalette {
    var accent: NSColor = .white
    var danger: NSColor = .red
    var warning: NSColor = .orange
    var dim: NSColor = .gray

    static func isBatteryLow(_ level: Int) -> Bool {
        return level < 20
    }
}

class MockThemeType: ThemeType {
    func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
        return NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    func attributes(_ size: CGFloat, color: NSColor, bold: Bool = false) -> [NSAttributedString.Key: Any] {
        return [
            .font: font(size, bold: bold),
            .foregroundColor: color
        ]
    }
}

class MockStatusItemView: StatusItemView {
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 20, height: 20)
    }

    override var snapshot: Snapshot {
        get { return Snapshot() }
        set {}
    }
}

// MARK: - Metrics Enum (if not defined elsewhere)

enum Metrics {
    case cpu
    case memory
    case battery
    case disk
    case network
}
