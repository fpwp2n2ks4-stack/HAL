//
//  VoiceCatalog.swift
//  HAL
//
//  Sélection des voix de synthèse dans la langue de l'application.
//
//  Chaque thème garde son timbre — féminin, masculin, métallique — mais
//  l'accent suit la langue choisie dans le menu. La sélection est refaite à
//  chaque phrase : changer de langue n'exige pas de relancer l'application.
//

import AVFoundation

/// Les voix disponibles dans la langue active, et les replis communs.
@MainActor
enum VoiceCatalog {

    /// Code BCP-47 de la langue parlée. On garde la région du système quand
    /// elle correspond à la langue de l'application (`fr-CA`, `en-GB`…) ;
    /// sinon on retombe sur la variante de référence.
    static var code: String {
        let language = Localization.current
        if let system = Locale.preferredLanguages.first,
           system.hasPrefix(language) {
            let parts = system.split(separator: "-")
            if parts.count >= 2 {
                return "\(parts[0])-\(parts[1].uppercased())"
            }
            return String(parts[0])
        }

        switch language {
        case "fr": return "fr-FR"
        case "es": return "es-ES"
        default: return "en-US"
        }
    }

    /// Les deux premières lettres du code : le préfixe des voix installées.
    static var family: String { String(code.prefix(2)) }

    /// Toutes les voix qui parlent la langue active. Si aucune n'est
    /// installée, on retombe sur l'anglais plutôt que sur le silence.
    static var voices: [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let matching = all.filter { $0.language.hasPrefix(family) }
        return matching.isEmpty ? all.filter { $0.language.hasPrefix("en") } : matching
    }

    /// Variante anglaise demandée par un thème : elle ne vaut que si
    /// l'application parle anglais. Dans une autre langue, c'est le code de
    /// cette langue qui s'applique.
    static func localized(_ english: String) -> String {
        Localization.current == "en" ? english : code
    }

    /// Voix système, si elle parle la langue active.
    static var systemVoice: AVSpeechSynthesisVoice? {
        guard let voice = AVSpeechSynthesisVoice(language: nil),
              voice.language.hasPrefix(family) else { return nil }
        return voice
    }

    /// Dernier recours : une voix de la langue active, sinon la voix
    /// système, sinon n'importe quelle voix. Mieux vaut une phrase avec un
    /// accent inattendu qu'un silence.
    static var fallback: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: code)
            ?? voices.first
            ?? AVSpeechSynthesisVoice(language: nil)
            ?? AVSpeechSynthesisVoice.speechVoices().first
    }
}
