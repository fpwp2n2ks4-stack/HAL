//
//  GERTYVoice.swift
//  HAL
//
//  La voix de GERTY 3000 : polie, posée, neutre à l'excès. Trop polie.
//  « Goodnight, Sam. » dit sur ce ton résonne différemment — et dans la
//  langue de l'application, la politesse reste intacte.
//
//  Ordre de préférence, dans la langue de l'application :
//    1. une voix neutre, posée, légèrement lointaine ;
//    2. une voix britannique sobre, pas chaleureuse ;
//    3. la voix système en dernier recours.
//

import AVFoundation

@MainActor
final class GERTYVoice: ThemeVoice {

    static let shared = GERTYVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private static let preferredNames = [
        "Daniel", "Oliver", "Alex", "Fred"
    ]

    /// Voix retenue à chaque phrase, selon la langue active.
    private var voice: AVSpeechSynthesisVoice? {
        let candidates = VoiceCatalog.voices

        let named = Self.preferredNames.lazy
            .compactMap { name in candidates.first { $0.name == name } }
            .first

        let male = candidates.first { $0.gender == .male && $0.quality == .enhanced }
            ?? candidates.first { $0.gender == .male }
        let british = AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-GB"))
        let american = AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-US"))

        return named
            ?? male
            ?? british
            ?? american
            ?? candidates.first
            ?? VoiceCatalog.fallback
    }

    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    /// Dit la phrase poliment, en interrompant la précédente. Toujours
    /// aimable. Toujours mesuré.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Lent, plat, un peu distant : la politesse d'un système isolé.
        utterance.rate = 0.38
        utterance.pitchMultiplier = 0.88
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
