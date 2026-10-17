import AVFoundation
import Foundation

@MainActor final class SpeechService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String, rate: Double) throws {
        guard let voice = AVSpeechSynthesisVoice(language: "ja-JP") else { throw SpeechError.noVoice }
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try AVAudioSession.sharedInstance().setActive(true)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = Float(rate)
        synthesizer.speak(utterance)
    }
    enum SpeechError: LocalizedError {
        case noVoice
        var errorDescription: String? {
            "A voz japonesa não está disponível. Baixe uma voz em japonês nos ajustes de acessibilidade do iPhone para ouvir também offline."
        }
    }
}
