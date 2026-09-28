import AVFoundation
import Foundation

/// 問題文などの音声読み上げ（音声出力）を管理するクラス
@MainActor
final class SpeechOutputService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinishedHandler: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// テキストを音声で読み上げる
    func speak(text: String, onFinished: @escaping () -> Void) throws {
        onFinishedHandler = onFinished

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    /// 読み上げを停止する
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        onFinishedHandler = nil
    }
}

extension SpeechOutputService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            let handler = self?.onFinishedHandler
            self?.onFinishedHandler = nil
            handler?()
        }
    }
}
