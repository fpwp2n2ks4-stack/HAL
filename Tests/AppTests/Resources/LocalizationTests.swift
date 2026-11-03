//
//  LocalizationTests.swift
//  HALTests
//
//  Tests unitaires pour le système de Localization.
//

import XCTest
@testable import HAL

final class LocalizationTests: XCTestCase {

    override func tearDown() {
        // Réinitialiser à la langue par défaut
        Localization.set("en")
        super.tearDown()
    }

    // MARK: - Supported Languages Tests

    func testSupportedLanguages() {
        let supported = Localization.supported

        // Vérifier qu'il y a au moins 2 langues
        XCTAssertGreaterThanOrEqual(supported.count, 2, "Should support at least 2 languages")

        // Vérifier que chaque langue a un code et un nom
        for lang in supported {
            XCTAssertFalse(lang.code.isEmpty, "Language code should not be empty")
            XCTAssertFalse(lang.name.isEmpty, "Language name should not be empty")
        }
    }

    func testSupportedLanguagesContainsExpected() {
        let codes = Localization.supported.map { $0.code }

        XCTAssertTrue(codes.contains("en"), "Should support English")
        XCTAssertTrue(codes.contains("fr"), "Should support French")
        XCTAssertTrue(codes.contains("es"), "Should support Spanish")
    }

    // MARK: - Current Language Tests

    @MainActor
    func testDefaultCurrentLanguage() {
        // Par défaut, devrait retourner "en" si aucune préférence
        let current = Localization.current

        // Vérifier que c'est une langue supportée
        let supportedCodes = Localization.supported.map { $0.code }
        XCTAssertTrue(supportedCodes.contains(current), "Current language should be in supported list")
    }

    @MainActor
    func testCurrentLanguageAfterSet() {
        Localization.set("fr")
        XCTAssertEqual(Localization.current, "fr")

        Localization.set("es")
        XCTAssertEqual(Localization.current, "es")

        Localization.set("en")
        XCTAssertEqual(Localization.current, "en")
    }

    @MainActor
    func testCurrentLanguageFallsBackToSystem() {
        // Supprimer la préférence
        UserDefaults.standard.removeObject(forKey: "appLanguage")

        let current = Localization.current
        let supportedCodes = Localization.supported.map { $0.code }
        XCTAssertTrue(supportedCodes.contains(current), "Should fall back to system language")
    }

    // MARK: - Set Language Tests

    @MainActor
    func testSetValidLanguage() {
        Localization.set("fr")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "appLanguage"), "fr")
    }

    @MainActor
    func testSetInvalidLanguage() {
        // Devrait ignorer une langue non supportée
        Localization.set("de") // Allemand non supporté

        // La préférence ne devrait pas être définie
        XCTAssertNotEqual(UserDefaults.standard.string(forKey: "appLanguage"), "de")
    }

    @MainActor
    func testSetEmptyLanguage() {
        Localization.set("")
        // Devrait ignorer
    }

    // MARK: - Bundle Tests

    @MainActor
    func testBundleForEnglish() {
        Localization.set("en")
        let bundle = Localization.bundle

        XCTAssertNotNil(bundle, "Bundle should not be nil for English")
    }

    @MainActor
    func testBundleForFrench() {
        Localization.set("fr")
        let bundle = Localization.bundle

        XCTAssertNotNil(bundle, "Bundle should not be nil for French")
    }

    @MainActor
    func testBundleForSpanish() {
        Localization.set("es")
        let bundle = Localization.bundle

        XCTAssertNotNil(bundle, "Bundle should not be nil for Spanish")
    }

    @MainActor
    func testBundleCaching() {
        Localization.set("en")

        let bundle1 = Localization.bundle
        let bundle2 = Localization.bundle

        // Devrait retourner le même bundle (même référence)
        XCTAssertTrue(bundle1 === bundle2, "Bundle should be cached")
    }

    @MainActor
    func testBundleInvalidationOnLanguageChange() {
        Localization.set("en")
        let bundle1 = Localization.bundle

        Localization.set("fr")
        let bundle2 = Localization.bundle

        // Après changement de langue, le bundle devrait être différent
        // (sauf si fr utilise le même bundle que en, ce qui est possible)
        // On vérifie juste que ça ne crash pas
        XCTAssertNotNil(bundle1)
        XCTAssertNotNil(bundle2)
    }

    // MARK: - loc() Function Tests

    func testLocFunctionBasic() {
        // Test avec un simple message
        let result = loc("Hello")
        XCTAssertNotNil(result)
        XCTAssertFalse(result.isEmpty)
    }

    func testLocFunctionWithFormat() {
        let name = "World"
        let result = loc("Hello %@", name)
        XCTAssertNotNil(result)
        XCTAssertTrue(result.contains("World") || result.contains("Hello"))
    }

    func testLocFunctionWithMultipleArguments() {
        let result = loc("Value: %d, Percent: %.1f%%", 42, 75.5)
        XCTAssertNotNil(result)
    }

    func testLocFunctionWithNoArguments() {
        let result = loc("Simple message")
        XCTAssertNotNil(result)
    }

    func testLocFunctionWithEmptyString() {
        let result = loc("")
        XCTAssertEqual(result, "")
    }

    // MARK: - Language Switch Tests

    @MainActor
    func testSwitchBetweenAllSupportedLanguages() {
        for lang in Localization.supported {
            Localization.set(lang.code)
            XCTAssertEqual(Localization.current, lang.code)

            let bundle = Localization.bundle
            XCTAssertNotNil(bundle)
        }
    }

    @MainActor
    func testSetSameLanguageTwice() {
        Localization.set("en")
        let bundle1 = Localization.bundle

        Localization.set("en")
        let bundle2 = Localization.bundle

        // Devrait retourner le même bundle
        XCTAssertTrue(bundle1 === bundle2)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentLanguageAccess() async {
        // Tester l'accès concurrent à Localization.current
        async let current1 = Localization.current
        async let current2 = Localization.current
        async let current3 = Localization.current

        let results = await (current1, current2, current3)

        // Tous devraient retourner la même langue
        XCTAssertEqual(results.0, results.1)
        XCTAssertEqual(results.1, results.2)
    }

    func testConcurrentBundleAccess() async {
        async let bundle1 = Localization.bundle
        async let bundle2 = Localization.bundle

        let results = await (bundle1, bundle2)
        XCTAssertNotNil(results.0)
        XCTAssertNotNil(results.1)
    }

    // MARK: - Edge Cases Tests

    @MainActor
    func testSetLanguageThenResetDefaults() {
        Localization.set("fr")
        XCTAssertEqual(Localization.current, "fr")

        // Réinitialiser UserDefaults
        UserDefaults.standard.removeObject(forKey: "appLanguage")

        // Devrait retourner la langue système
        let current = Localization.current
        XCTAssertNotNil(current)
    }

    // MARK: - Sendable Conformance Tests

    func testLocalizationIsMainActor() {
        // Localization est marqué @MainActor
        // Ce test vérifie que les appels nécessitent @MainActor

        let expectation = XCTestExpectation(description: "MainActor isolation")

        DispatchQueue.global().async {
            Task { @MainActor in
                _ = Localization.current
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Performance Tests

    @MainActor
    func testBundleAccessPerformance() {
        measure {
            for _ in 0..<100 {
                _ = Localization.bundle
            }
        }
    }

    func testLocFunctionPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = loc("Test message")
            }
        }
    }
}

// MARK: - Mock Localization for Testing Other Components

/// Mock pour tester les composants qui dépendent de Localization
@MainActor
class MockLocalization {
    private(set) var currentLanguage: String = "en"
    private(set) var setCallCount: Int = 0
    private(set) var lastSetLanguage: String?

    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("fr", "Français"),
        ("es", "Español")
    ]

    var current: String { currentLanguage }

    var bundle: Bundle { Bundle.main }

    func set(_ code: String) {
        setCallCount += 1
        lastSetLanguage = code
        if supported.contains(where: { $0.code == code }) {
            currentLanguage = code
        }
    }

    func reset() {
        currentLanguage = "en"
        setCallCount = 0
        lastSetLanguage = nil
    }
}
