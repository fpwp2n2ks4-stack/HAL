//
//  ThemeManager.swift
//  HAL
//
//  Sélection et persistance du thème. Le choix survit au redémarrage ;
//  le changement à chaud est appliqué par l'`AppDelegate`, qui écoute
//  `.themeDidChange` — ou plutôt qui appelle `select(_:)` et reconstruit
//  ce qui doit l'être.
//

import Foundation

extension Notification.Name {
    /// Publiée après un changement de thème effectif.
    static let themeDidChange = Notification.Name("ThemeManager.themeDidChange")
}

@MainActor
final class ThemeManager {

    static let shared = ThemeManager()

    /// Thèmes réellement implémentés, dans l'ordre du menu.
    let available: [ThemeDefinition]

    private let byID: [ThemeID: ThemeDefinition]
    private static let defaultsKey = "themeID"

    private(set) var current: ThemeDefinition

    private init() {
        let themes: [ThemeDefinition] = [
            HALTheme(), LCARSTheme(), BladeRunnerTheme(), WarGamesTheme(), MoonTheme(),
            MatrixTheme(), ArkTheme(), ToastyTheme()
        ]
        let map = Dictionary(uniqueKeysWithValues: themes.map { ($0.id, $0) })
        available = themes
        byID = map

        let saved = UserDefaults.standard.string(forKey: Self.defaultsKey)
            .flatMap(ThemeID.init(rawValue:))
        current = saved.flatMap { map[$0] } ?? themes[0]
    }

    /// Bascule vers un thème. Renvoie `nil` si l'identité est inconnue ou
    /// déjà active : rien à reconstruire, rien à notifier.
    @discardableResult
    func select(_ id: ThemeID) -> ThemeDefinition? {
        guard let theme = byID[id], theme.id != current.id else { return nil }
        current = theme
        UserDefaults.standard.set(id.rawValue, forKey: Self.defaultsKey)
        NotificationCenter.default.post(name: .themeDidChange, object: self)
        return theme
    }

    func theme(for id: ThemeID) -> ThemeDefinition? { byID[id] }
}
