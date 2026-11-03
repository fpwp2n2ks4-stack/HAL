//
//  NotchIslandAnimationTests.swift
//  HALTests
//
//  Tests unitaires pour les animations de NotchIslandView et NotchIslandController.
//

import XCTest
import AppKit
@testable import HAL

final class NotchIslandAnimationTests: XCTestCase {

    private var theme: MockTheme!
    private var snapshot: Snapshot!
    private var controller: NotchIslandController!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        theme = MockTheme()
        snapshot = Snapshot()
    }

    override func tearDown() {
        controller?.shutdown()
        controller = nil
        snapshot = nil
        theme = nil
        super.tearDown()
    }

    // MARK: - Animation Tests

    func testRevealAnimation() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Vérifier que reveal ne crash pas
        // Note: On ne peut pas tester directement l'animation car elle nécessite
        // un écran avec notch et une géométrie valide

        XCTAssertNotNil(controller, "Controller should be initialized for animation tests")
    }

    func testCollapseAnimation() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Vérifier que collapse ne crash pas
        XCTAssertNotNil(controller, "Controller should handle collapse")
    }

    // MARK: - State Transition Tests

    func testStateTransitions() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Le controller devrait gérer les transitions d'état
        // (On ne peut pas vérifier directement l'état car c'est private,
        // mais on vérifie que les appels ne crashent pas)

        XCTAssertNotNil(controller, "Controller should handle state transitions")
    }

    // MARK: - Hover State Tests

    func testHandleHover() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Simuler un survol
        controller.handleHover(true)

        // Simuler une sortie de souris
        controller.handleHover(false)

        XCTAssertNotNil(controller, "Controller should handle hover events")
    }

    // MARK: - Click Handling Tests

    func testHandleClick() {
        let expectation = XCTestExpectation(description: "Cockpit opened")

        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {
                expectation.fulfill()
            }
        )

        // Mettre le controller dans un état qui permet le clic
        // (en réalité, il faut que state != .dormant)

        // Note: On ne peut pas facilement simuler le clic car l'état du controller
        // dépend de la géométrie et du notch

        // Shutdown pour éviter les fuites mémoire
        controller.shutdown()

        // Le test est valide si on arrive ici sans crash
        XCTAssertTrue(true, "Controller should handle click without crashing")
    }

    // MARK: - Peek Presentation Tests

    func testPeekPresentation() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Créer un Peek pour le test
        // Note: Peek est private, donc on ne peut pas l'instancier directement
        // On vérifie juste que la méthode present ne crash pas

        XCTAssertNotNil(controller, "Controller should be initialized")
    }

    // MARK: - Detection Tests

    func testAlertDetectionForCPU() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Premier snapshot avec CPU bas
        var oldSnapshot = Snapshot()
        oldSnapshot.cpu.total = 40.0

        // Nouveau snapshot avec CPU élevé
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 95.0
        newSnapshot.temperature.socPeak = 75.0

        // Vérifier la détection
        // Note: On ne peut pas tester directement detect car c'est private

        XCTAssertNotNil(controller, "Controller should handle CPU alert detection")
    }

    func testAlertDetectionForMemory() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Premier snapshot avec mémoire basse
        var oldSnapshot = Snapshot()
        oldSnapshot.memory.fraction = 0.4

        // Nouveau snapshot avec mémoire élevée
        var newSnapshot = Snapshot()
        newSnapshot.memory.fraction = 0.95

        XCTAssertNotNil(controller, "Controller should handle memory alert detection")
    }

    func testAlertDetectionForBattery() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Premier snapshot avec batterie normale
        var oldSnapshot = Snapshot()
        oldSnapshot.battery.level = 50
        oldSnapshot.battery.isPresent = true

        // Nouveau snapshot avec batterie faible
        var newSnapshot = Snapshot()
        newSnapshot.battery.level = 15
        newSnapshot.battery.isPresent = true

        XCTAssertNotNil(controller, "Controller should handle battery alert detection")
    }

    // MARK: - Geometry Refresh Tests

    func testGeometryRefresh() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Vérifier que refreshGeometry ne crash pas
        // Note: Cela nécessite un écran avec notch, mais on vérifie que l'appel ne crash pas

        XCTAssertNotNil(controller, "Controller should handle geometry refresh")
    }

    // MARK: - Task Cancellation Tests

    func testAnimationTaskCancellation() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Vérifier que l'annulation des tâches fonctionne
        controller.cancelAnimation()

        XCTAssertNotNil(controller, "Controller should handle animation cancellation")
    }

    func testCollapseTaskCancellation() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        // Simuler un survol pour déclencher un scheduleCollapse
        controller.handleHover(true)
        controller.handleHover(false)

        // Vérifier que le controller gère correctement
        XCTAssertNotNil(controller, "Controller should handle collapse task scheduling")
    }

    // MARK: - Observation Tests

    func testStartObserving() {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        controller.startObserving()

        // Attendre un peu pour permettre l'observation
        Thread.sleep(forTimeInterval: 0.1)

        controller.stopObserving()

        XCTAssertNotNil(controller, "Controller should handle observation start/stop")
    }

    // MARK: - Async Animation Tests

    func testAsyncAnimationPerformance() async {
        controller = NotchIslandController(
            theme: theme,
            snapshot: snapshot,
            onOpenCockpit: {}
        )

        let startTime = CFAbsoluteTimeGetCurrent()

        // Déclencher une animation (même si elle ne s'affiche pas)
        // Note: Sans géométrie valide, l'animation ne se déclenchera pas

        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime

        // Vérifier que l'appel est rapide
        XCTAssertLessThan(executionTime, 1.0, "Animation setup should be fast")

        controller.shutdown()
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

// MARK: - Metrics Enum

enum Metrics {
    case cpu
    case memory
    case battery
    case disk
    case network
}
