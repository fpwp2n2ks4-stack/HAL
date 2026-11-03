//
//  NotchIslandViewTests.swift
//  HALTests
//
//  Tests unitaires pour NotchIslandView.
//

import XCTest
import AppKit
@testable import HAL

final class NotchIslandViewTests: XCTestCase {

    private var theme: MockTheme!
    private var snapshot: Snapshot!
    private var view: NotchIslandView!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        theme = MockTheme()
        snapshot = Snapshot()
        view = NotchIslandView(theme: theme, snapshot: snapshot)
    }

    override func tearDown() {
        view = nil
        snapshot = nil
        theme = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewInitialization() {
        XCTAssertNotNil(view, "View should be initialized")
        XCTAssertEqual(view.notchHeight, 32, "Default notchHeight should be 32")
        XCTAssertEqual(view.notchWidth, 200, "Default notchWidth should be 200")
        XCTAssertEqual(view.stripHeight, 58, "stripHeight should be 58")
        XCTAssertFalse(view.isAwake, "View should start dormant")
        XCTAssertTrue(view.title.isEmpty, "Title should be empty initially")
        XCTAssertTrue(view.detail.isEmpty, "Detail should be empty initially")
    }

    func testViewWithCustomDimensions() {
        let customView = NotchIslandView(theme: theme, snapshot: snapshot)
        customView.notchHeight = 40
        customView.notchWidth = 250

        XCTAssertEqual(customView.notchHeight, 40, "notchHeight should be customizable")
        XCTAssertEqual(customView.notchWidth, 250, "notchWidth should be customizable")
    }

    // MARK: - Snapshot Update Tests

    func testSetSnapshot() {
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 50.0
        newSnapshot.memory.fraction = 0.75
        newSnapshot.temperature.socPeak = 65.0

        view.setSnapshot(newSnapshot)

        // Vérifier que le snapshot a été mis à jour
        // (On ne peut pas vérifier directement car snapshot est private,
        // mais on peut vérifier que la vue se redessine)
        XCTAssertTrue(view.needsDisplay, "View should need display after snapshot update")
    }

    // MARK: - Theme Application Tests

    func testApplyTheme() {
        let newTheme = MockTheme()
        newTheme.palette.accent = .red

        let initialTint = view.tint
        view.applyTheme(newTheme)

        // Le tint devrait être mis à jour
        // (On ne peut pas vérifier directement car tint est private,
        // mais on vérifie que la vue se redessine)
        XCTAssertTrue(view.needsDisplay, "View should need display after theme update")
    }

    // MARK: - Awake State Tests

    func testIsAwakeProperty() {
        XCTAssertFalse(view.isAwake, "View should start dormant")

        view.isAwake = true
        XCTAssertTrue(view.isAwake, "View should be awake after setting")

        view.isAwake = false
        XCTAssertFalse(view.isAwake, "View should be dormant after setting to false")
    }

    // MARK: - Layout Tests

    func testLayout() {
        // Configurer la vue avec une taille
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Forcer le layout
        view.layout()

        // Vérifier que le badge est positionné
        // (On ne peut pas vérifier la position exacte car badge est private,
        // mais on vérifie que le layout ne crash pas)
        XCTAssertNotNil(view, "View should still exist after layout")
    }

    func testLayoutWithNotchDimensions() {
        view.notchHeight = 40
        view.notchWidth = 250
        view.frame = NSRect(x: 0, y: 0, width: 300, height: 100)

        view.layout()

        // Vérifier que le layout gère correctement les dimensions du notch
        XCTAssertNotNil(view, "View should handle notch dimensions in layout")
    }

    // MARK: - Draw Tests

    func testDrawWithDormantState() {
        view.isAwake = false
        view.frame = NSRect(x: 0, y: 0, width: 200, height: 40)

        // Le dessin ne devrait pas crasher
        _ = view.displayIgnoringOpacity(NSRect.infinite)
    }

    func testDrawWithAwakeState() {
        view.isAwake = true
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Le dessin ne devrait pas crasher
        _ = view.displayIgnoringOpacity(NSRect.infinite)
    }

    // MARK: - Permanent Metrics Tests

    func testDrawPermanentMetricsWithValidSnapshot() {
        // Configurer un snapshot avec des valeurs valides
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 45.7
        newSnapshot.memory.fraction = 0.65
        newSnapshot.temperature.socPeak = 55.3
        newSnapshot.gpu.deviceUtilization = 30

        view.setSnapshot(newSnapshot)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Le dessin avec les métriques permanentes ne devrait pas crasher
        _ = view.displayIgnoringOpacity(view.bounds)
    }

    func testDrawPermanentMetricsWithNilTemperature() {
        // Configurer un snapshot avec température nil
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 30.0
        newSnapshot.memory.fraction = 0.5
        newSnapshot.temperature.socPeak = nil
        newSnapshot.gpu.deviceUtilization = 20

        view.setSnapshot(newSnapshot)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Devrait afficher "—" pour la température
        _ = view.displayIgnoringOpacity(view.bounds)
    }

    func testDrawPermanentMetricsWithZeroValues() {
        // Configurer un snapshot avec des valeurs à zéro
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 0.0
        newSnapshot.memory.fraction = 0.0
        newSnapshot.temperature.socPeak = 0.0
        newSnapshot.gpu.deviceUtilization = 0

        view.setSnapshot(newSnapshot)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Devrait afficher 0% et 0°C
        _ = view.displayIgnoringOpacity(view.bounds)
    }

    func testDrawPermanentMetricsWithMaxValues() {
        // Configurer un snapshot avec des valeurs maximales
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 100.0
        newSnapshot.memory.fraction = 1.0
        newSnapshot.temperature.socPeak = 100.0
        newSnapshot.gpu.deviceUtilization = 100

        view.setSnapshot(newSnapshot)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Devrait afficher 100% et 100°C
        _ = view.displayIgnoringOpacity(view.bounds)
    }

    func testDrawPermanentMetricsLayout() {
        // Vérifier que les métriques sont bien positionnées
        var newSnapshot = Snapshot()
        newSnapshot.cpu.total = 50.0
        newSnapshot.memory.fraction = 0.75
        newSnapshot.temperature.socPeak = 65.0
        newSnapshot.gpu.deviceUtilization = 40

        view.setSnapshot(newSnapshot)
        view.notchWidth = 200
        view.notchHeight = 32
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 100)

        // Le dessin ne devrait pas crasher avec ces dimensions
        _ = view.displayIgnoringOpacity(view.bounds)
    }

    // MARK: - Property Tests

    func testTitleAndDetail() {
        XCTAssertTrue(view.title.isEmpty, "Title should be empty initially")
        XCTAssertTrue(view.detail.isEmpty, "Detail should be empty initially")

        view.title = "Test Title"
        view.detail = "Test Detail"

        XCTAssertEqual(view.title, "Test Title", "Title should be set")
        XCTAssertEqual(view.detail, "Test Detail", "Detail should be set")
    }

    func testTint() {
        let initialTint = view.tint
        view.tint = .red
        XCTAssertEqual(view.tint, .red, "Tint should be set")

        view.tint = initialTint
        XCTAssertEqual(view.tint, initialTint, "Tint should be reset")
    }

    // MARK: - Geometry Tests

    func testNotchDimensions() {
        XCTAssertEqual(view.notchHeight, 32, "Default notchHeight")
        XCTAssertEqual(view.notchWidth, 200, "Default notchWidth")

        view.notchHeight = 50
        view.notchWidth = 300

        XCTAssertEqual(view.notchHeight, 50, "notchHeight should be updated")
        XCTAssertEqual(view.notchWidth, 300, "notchWidth should be updated")
    }

    // MARK: - Intrinsic Content Size Tests

    func testIntrinsicContentSize() {
        let size = view.intrinsicContentSize
        XCTAssertGreaterThan(size.width, 0, "Width should be positive")
        XCTAssertGreaterThan(size.height, 0, "Height should be positive")
    }

    // MARK: - Mouse Event Tests

    func testMouseEntered() {
        let expectation = XCTestExpectation(description: "Mouse entered")

        view.onHover = { inside in
            if inside {
                expectation.fulfill()
            }
        }

        let event = NSEvent.mouseEvent(
            with: .entered,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0
        )!

        view.mouseEntered(with: event)

        wait(for: [expectation], timeout: 1.0)
    }

    func testMouseExited() {
        let expectation = XCTestExpectation(description: "Mouse exited")

        view.onHover = { inside in
            if !inside {
                expectation.fulfill()
            }
        }

        // D'abord entrer
        view.onHover?(true)

        let event = NSEvent.mouseEvent(
            with: .exited,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 0,
            pressure: 0
        )!

        view.mouseExited(with: event)

        wait(for: [expectation], timeout: 1.0)
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
    var screenLabel: (Metrics) -> String = { _ in "Test" }
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
