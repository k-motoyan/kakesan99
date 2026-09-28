import Foundation
import SwiftUI

@Observable
@MainActor
final class QuizViewModel {
    enum Phase: Equatable {
        case idle
        case speaking
        case listening
        case result(correct: Bool)
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var currentQuestion: QuizQuestion?
    private(set) var progress: Double = 0
    private(set) var recognizedText = ""
    private(set) var recognizedAnswer: Int?

    @ObservationIgnored private let speechOutputService: SpeechOutputService
    @ObservationIgnored private let speechInputService: SpeechInputService
    @ObservationIgnored private let answerExtractor: AnswerExtractor
    @ObservationIgnored private var progressTimer: Timer?
    private let listenDuration: TimeInterval = 5

    init(
        speechOutputService: SpeechOutputService? = nil,
        speechInputService: SpeechInputService? = nil,
        answerExtractor: AnswerExtractor = .shared
    ) {
        self.speechOutputService = speechOutputService ?? SpeechOutputService()
        self.speechInputService = speechInputService ?? SpeechInputService()
        self.answerExtractor = answerExtractor
    }

    var isBusy: Bool {
        phase == .speaking || phase == .listening
    }

    func askQuestion() {
        guard !isBusy else { return }
        Task {
            guard await speechInputService.requestPermissions() else {
                phase = .error("マイクと音声認識の許可が必要です。設定アプリから許可してください。")
                return
            }
            startQuestion()
        }
    }

    private func startQuestion() {
        recognizedText = ""
        recognizedAnswer = nil
        progress = 0
        currentQuestion = QuizData.allQuestions.randomElement()
        guard let question = currentQuestion else { return }

        phase = .speaking
        do {
            try speechOutputService.speak(text: question.speechText) { [weak self] in
                self?.startListening()
            }
        } catch {
            phase = .error("オーディオの初期化に失敗しました: \(error.localizedDescription)")
        }
    }

    private func startListening() {
        do {
            try speechInputService.startListening { [weak self] text in
                self?.recognizedText = text
            }
            phase = .listening
            startProgressTimer()
        } catch {
            phase = .error("マイクの起動に失敗しました: \(error.localizedDescription)")
        }
    }

    private func startProgressTimer() {
        let startDate = Date()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let elapsed = Date().timeIntervalSince(startDate)
                self.progress = min(elapsed / self.listenDuration, 1)
                if elapsed >= self.listenDuration {
                    self.finishListening()
                }
            }
        }
    }

    private func finishListening() {
        guard phase == .listening else { return }
        progressTimer?.invalidate()
        progressTimer = nil

        speechInputService.stopListening()
        evaluateAnswer()
    }

    private func evaluateAnswer() {
        guard let question = currentQuestion else { return }
        let text = recognizedText
        Task {
            let extracted = await answerExtractor.extractNumber(from: text)
            guard currentQuestion?.id == question.id else { return }
            recognizedAnswer = extracted
            phase = .result(correct: extracted == question.answer)
        }
    }

    // 後方互換性およびヘルパーメソッド
    nonisolated static func extractNumber(from text: String) async -> Int? {
        await AnswerExtractor.shared.extractNumber(from: text)
    }
}
