//
//  WOPRVoice.swift
//  HAL
//
//  La voix de WOPR : plate, synthétique, sans respiration. En 1983, un
//  ordinateur ne cherchait pas à imiter l'humain — il lisait ses réponses.
//  Les répliques suivent la langue de l'application ; la hauteur et le débit
//  gardent le timbre métallique de Joshua.
//
//  Ordre de préférence, dans la langue de l'application :
//    1. une voix de synthèse assumée (Fred, Zarvox, Albert), la plus proche
//       du timbre métallique de Joshua ;
//    2. une voix masculine, posée et lente ;
//    3. la voix de la langue active, faute de mieux.
//

import AVFoundation

@MainActor
final class WOPRVoice: ThemeVoice {

    static let shared = WOPRVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private static let preferredNames = [
        "Fred", "Zarvox", "Albert", "Ralph", "Trinoids"
    ]

    /// Voix retenue à chaque phrase, selon la langue active.
    private var voice: AVSpeechSynthesisVoice? {
        let candidates = VoiceCatalog.voices

        let named = Self.preferredNames.lazy
            .compactMap { name in candidates.first { $0.name == name } }
            .first

        let male = candidates.first { $0.gender == .male && $0.quality == .enhanced }
            ?? candidates.first { $0.gender == .male }
        let american = AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-US"))
        let fallback = AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en"))

        return named
            ?? male
            ?? american
            ?? fallback
            ?? candidates.first
            ?? VoiceCatalog.fallback
    }

    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    /// Dit la phrase en interrompant la précédente : WOPR ne bavarde pas,
    /// il énonce un résultat.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Débit lent et hauteur basse : la machine de 1983 pesait trois
        // tonnes et parlait comme telle.
        utterance.rate = 0.42
        utterance.pitchMultiplier = 0.78
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
