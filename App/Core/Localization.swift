//
//  Localization.swift
//  HAL — Hardware Autopsy Live
//
//  Support multilingue de l'interface (EN/FR/ES).
//
//  Aucune dépendance externe : uniquement Foundation (`NSLocalizedString`,
//  `Bundle`, `UserDefaults`). Les clés de traduction sont le texte anglais :
//  si une traduction manque, l'anglais s'affiche automatiquement — la langue
//  de base n'a donc pas besoin de table dédiée.
//
//  Les répliques cultes sont des clés anglaises, traduites comme le reste de
//  l'interface : l'infobulle et la synthèse vocale suivent ainsi la langue
//  choisie. Seul le dernier mot affiché à la fermeture garde sa langue
//  d'origine ; sa version prononcée est traduite.
//

import Foundation

/// Fonction de localisation avec support de formatage - globale pour être accessible partout
func loc(_ format: String, _ args: CVarArg...) -> String {
    if args.isEmpty {
        return NSLocalizedString(format, comment: "")
    }
    return String(format: NSLocalizedString(format, comment: ""), arguments: args)
}

/// Gestionnaire de la langue de l'interface.
@MainActor
enum Localization {

    /// Langues proposées, dans l'ordre d'affichage du menu.
    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("fr", "Français"),
        ("es", "Español")
    ]

    private static let preferenceKey = "appLanguage"
    private static var cachedCode: String?
    private static var cachedBundle: Bundle?

    /// Code de la langue active : préférence utilisateur, sinon langue système.
    static var current: String {
        if let saved = UserDefaults.standard.string(forKey: preferenceKey),
           supported.contains(where: { $0.code == saved }) {
            return saved
        }
        let system = Locale.preferredLanguages.first ?? "en"
        return supported.first { system.hasPrefix($0.code) }?.code ?? "en"
    }

    /// Force la langue voulue et invalide le bundle mis en cache.
    static func set(_ code: String) {
        guard supported.contains(where: { $0.code == code }) else { return }
        UserDefaults.standard.set(code, forKey: preferenceKey)
        cachedCode = nil
        cachedBundle = nil
    }

    /// Bundle du `.lproj` correspondant à la langue active.
    ///
    /// Retombe sur `Bundle.main` si le dossier est absent (outils `verify`,
    /// qui n'embarquent pas les ressources) : `NSLocalizedString` renvoie
    /// alors la clé, c'est-à-dire l'anglais.
    static var bundle: Bundle {
        let code = current
        if let currentCachedCode = cachedCode, currentCachedCode == code, let cachedBundle = cachedBundle {
            return cachedBundle
        }

        let resolved: Bundle
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let specialized = Bundle(path: path) {
            resolved = specialized
        } else {
            resolved = Bundle.main
        }
        cachedCode = code
        cachedBundle = resolved
        return resolved
    }
}
