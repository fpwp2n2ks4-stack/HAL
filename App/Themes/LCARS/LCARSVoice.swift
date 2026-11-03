//
//  LCARSVoice.swift
//  HAL
//
//  La voix de l'ordinateur de bord. Au survol de l'insigne du panneau, la
//  machine dit à voix haute la réplique que l'infobulle affiche.
//
//  Ordre de préférence, dans la langue de l'application :
//    1. une voix féminine, de préférence améliorée — la voix de
//       l'ordinateur de la Fédération est posée, neutre, sans affect ;
//    2. parmi elles, Samantha / Ava / Allison / Susan, les plus proches du
//       timbre de Majel Barrett ;
//    3. sinon n'importe quelle voix de la langue active ;
//    4. en dernier recours, la voix système : mieux vaut une phrase avec
//       l'accent local qu'un silence.
//
//  La synthèse est fournie par le système : aucune dépendance, rien à
//  télécharger, ça marche hors ligne.
//

import AVFoundation

/// Voix du vaisseau. Un seul exemplaire : deux phrases simultanées
/// produiraient un brouhaha indigne d'un ordinateur de bord.
@MainActor
final class ShipComputerVoice: ThemeVoice {

    static let shared = ShipComputerVoice()

    private let synthesizer = AVSpeechSynthesizer()

    /// Noms qui sonnent le plus « ordinateur de la Fédération ».
    private static let preferredNames = [
        "Samantha", "Ava", "Allison", "Susan", "Zoe", "Nicky", "Tessa"
    ]

    /// Voix retenue à chaque phrase, selon la langue active.
    private var voice: AVSpeechSynthesisVoice? {
        let candidates = VoiceCatalog.voices

        let named = Self.preferredNames.lazy
            .compactMap { name in candidates.first { $0.name == name } }
            .first

        let enhancedFemale = candidates.first {
            $0.gender == .female && $0.quality == .enhanced
        }
        let female = candidates.first { $0.gender == .female }
        let british = AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-GB"))
        let american = AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-US"))

        return named
            ?? enhancedFemale
            ?? female
            ?? british
            ?? american
            ?? candidates.first
            ?? VoiceCatalog.fallback
    }

    /// La voix trouvée, pour le diagnostic.
    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    /// Dit la phrase, en interrompant la précédente : on veut la dernière
    /// instruction de l'ordinateur, pas la file d'attente de ses rapports.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Débit égal et posé : l'ordinateur ne s'émeut jamais.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    /// Tait la machine — la synthèse doit cesser quand plus personne
    /// n'écoute, sinon un mot traîne après la fermeture du panneau.
    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
