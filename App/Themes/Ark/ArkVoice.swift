//
//  ArkVoice.swift
//  HAL
//
//  La voix d'Ark One : calme, nette, celle d'un ordinateur de bord qui
//  annonce les procédures sans élever le ton. L'équipage peut paniquer ;
//  pas la console. La langue suit celle de l'application.
//
//  Ordre de préférence, dans la langue active :
//    1. une voix féminine posée — Samantha, Ava, Allison, Susan ;
//    2. une voix féminine améliorée ;
//    3. n'importe quelle voix de la langue active ;
//    4. la voix système, faute de mieux.
//

import AVFoundation

@MainActor
final class ArkVoice: ThemeVoice {

    static let shared = ArkVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private static let preferredNames = [
        "Samantha", "Ava", "Allison", "Susan", "Zoe", "Tessa"
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

        return named
            ?? enhancedFemale
            ?? female
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-US"))
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en"))
            ?? candidates.first
            ?? VoiceCatalog.fallback
    }

    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    /// Dit la phrase en interrompant la précédente : une console de bord
    /// n'empile pas les annonces, elle donne la dernière instruction.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Débit régulier, sans emphase : la procédure avant l'émotion.
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
