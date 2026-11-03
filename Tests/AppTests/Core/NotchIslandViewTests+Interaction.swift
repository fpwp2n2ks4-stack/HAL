//
//  NotchIslandViewTests+Interaction.swift
//  HALTests
//
//  Les tests d'interaction de l'îlot du cran : clics gauche et droit,
//  modificateur, premier clic. Séparés du corps principal.
//

import XCTest

extension NotchIslandViewTests {

    func testMouseDown() {
        let expectation = XCTestExpectation(description: "Mouse down")

        view.onOpen = {
            expectation.fulfill()
        }

        let event = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )!

        view.mouseDown(with: event)

        wait(for: [expectation], timeout: 1.0)
    }

    func testRightMouseDown() {
        let expectation = XCTestExpectation(description: "Right mouse down")

        view.onContextMenu = { _ in
            expectation.fulfill()
        }

        let event = NSEvent.mouseEvent(
            with: .rightMouseDown,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )!

        view.rightMouseDown(with: event)

        wait(for: [expectation], timeout: 1.0)
    }

    func testControlClick() {
        let contextMenuExpectation = XCTestExpectation(description: "Control click")
        let openExpectation = XCTestExpectation(description: "Open not called")
        openExpectation.isInverted = true

        view.onContextMenu = { _ in
            contextMenuExpectation.fulfill()
        }

        view.onOpen = {
            openExpectation.fulfill()
        }

        let event = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 10, y: 10),
            modifierFlags: .control,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )!

        view.mouseDown(with: event)

        wait(for: [contextMenuExpectation, openExpectation], timeout: 1.0)
    }

    // MARK: - Accepts First Mouse Tests

    func testAcceptsFirstMouse() {
        XCTAssertTrue(view.acceptsFirstMouse(for: nil), "Should accept first mouse")
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

// MARK: - Formatters (if not defined elsewhere)

enum Formatters {
    static func bytes(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0fo", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1fKo", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1fMo", bytes / (1024 * 1024))
        } else {
            return String(format: "%.1fGo", bytes / (1024 * 1024 * 1024))
        }
    }
}
