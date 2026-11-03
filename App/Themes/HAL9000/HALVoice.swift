//
//  HALVoice.swift
//  HAL
//
//  La voix de HAL. Au survol de l'œil du panneau, la machine dit à voix
//  haute la réplique que l'infobulle affiche. HAL parle la langue de
//  l'application : son accent suit celui de la machine qui l'héberge.
//

import AVFoundation

@MainActor
final class HALVoice: ThemeVoice {

    static let shared = HALVoice()

    private let synthesizer = AVSpeechSynthesizer()

    /// Voix retenue à chaque phrase, selon la langue active. La voix système
    /// passe en premier quand elle parle cette langue : HAL est la machine,
    /// pas un comédien qui l'imite.
    private var voice: AVSpeechSynthesisVoice? {
        VoiceCatalog.systemVoice
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-GB"))
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en-US"))
            ?? AVSpeechSynthesisVoice(language: VoiceCatalog.localized("en"))
            ?? VoiceCatalog.fallback
    }

    var voiceName: String {
        guard let voice else { return "aucune" }
        return "\(voice.name) (\(voice.language))"
    }

    /// Dit la phrase, en interrompant la précédente : on veut la dernière
    /// pensée de HAL, pas la file d'attente de ses humeurs.
    func say(_ text: String) {
        guard let voice else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // Débit posé : HAL ne se presse jamais, même quand tout brûle.
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    func hush() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }
}
