//
//  MatrixVoice.swift
//  HAL
//
//  La voix de la Matrice : grave, lente, un peu détachée. Elle parle la
//  langue de l'application et n'empile pas les avertissements.
//

import AVFoundation

@MainActor
final class MatrixVoice: ThemeVoice {

    static let shared = MatrixVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private static let preferredNames = [
        "Daniel", "Oliver", "Alex", "Fred", "Thomas", "Jacques", "Jorge", "Diego"
    ]

    /// Voix retenue à chaque phrase, selon la langue active.
    private var voice: AVSpeechSynthesisVoice? {
        let candidates = VoiceCatalog.voices

        let named = Self.preferredNames.lazy
            .compactMap { name in candidates.first { $0.name == name } }
            .first

        let male = candidates.first { $0.gender == .male && $0.quality == .enhanced }
            ?? candidates.first { $0.gender == .male }

        return named
            ?? male
            ?? candidates.first
            ?? VoiceCatalog.fallback
    }

    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Grave et lent : la machine énonce, elle ne discute pas.
        utterance.rate = 0.40
        utterance.pitchMultiplier = 0.82
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
