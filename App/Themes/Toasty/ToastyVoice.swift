//
//  ToastyVoice.swift
//  HAL
//
//  La voix du grille-pain : calme, militaire, un rien trop posée — comme
//  un Cylon de 1978 qui dit « By your command. » sans se presser. Le
//  calme est le point commun des machines qui ont un plan.
//
//  Ordre de préférence, dans la langue de l'application :
//    1. une voix masculine grave, posée ;
//    2. une voix britannique sobre ;
//    3. la voix système en dernier recours.
//

import AVFoundation

@MainActor
final class ToastyVoice: ThemeVoice {

    static let shared = ToastyVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private static let preferredNames = [
        "Alex", "Daniel", "Oliver", "Fred"
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

    /// Dit la phrase posément, en interrompant la précédente. Jamais
    /// pressé, jamais élevé : la flotte n'aboie pas.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Lent et grave : le débit d'une machine qui sait qu'elle a le temps.
        utterance.rate = 0.42
        utterance.pitchMultiplier = 0.82
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
