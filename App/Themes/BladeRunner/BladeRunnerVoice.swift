//
//  BladeRunnerVoice.swift
//  HAL
//
//  La voix de la ville. Au survol de l'œil de Tyrell, la machine dit à voix
//  haute la réplique que l'infobulle affiche. Les répliques sont traduites ;
//  le timbre, lui, reste celui d'un récitant de film noir.
//
//  Ordre de préférence, dans la langue de l'application :
//    1. une voix masculine, de préférence britannique et améliorée — le ton
//       est posé, las, presque administratif ;
//    2. parmi elles, Daniel / Oliver / Arthur / Alex, les plus proches
//       d'un récitant de film noir ;
//    3. sinon n'importe quelle voix masculine ;
//    4. en dernier recours, la voix de la langue active.
//

import AVFoundation

@MainActor
final class BladeRunnerVoice: ThemeVoice {

    static let shared = BladeRunnerVoice()

    private let synthesizer = AVSpeechSynthesizer()

    private static let preferredNames = [
        "Daniel", "Oliver", "Arthur", "Alex", "Fred", "Tom"
    ]

    /// Voix retenue à chaque phrase, selon la langue active.
    private var voice: AVSpeechSynthesisVoice? {
        let candidates = VoiceCatalog.voices
        let britishLanguage = VoiceCatalog.localized("en-GB")

        let named = Self.preferredNames.lazy
            .compactMap { name in candidates.first { $0.name == name } }
            .first

        let british = candidates.first {
            $0.language == britishLanguage && $0.gender == .male && $0.quality == .enhanced
        }
        let male = candidates.first {
            $0.gender == .male && $0.quality == .enhanced
        }
        let anyBritish = candidates.first { $0.language == britishLanguage }
        let anyMale = candidates.first { $0.gender == .male }

        return named
            ?? british
            ?? male
            ?? anyBritish
            ?? anyMale
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-GB"))
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en"))
            ?? VoiceCatalog.fallback
    }

    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    /// Dit la phrase en interrompant la précédente : on veut le dernier
    /// souvenir du réplicant, pas la file d'attente de ses rapports.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Débit lent et grave : la pluie n'a jamais été pressée.
        utterance.rate = 0.40
        utterance.pitchMultiplier = 0.86
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
