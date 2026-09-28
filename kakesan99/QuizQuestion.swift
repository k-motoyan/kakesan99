import Foundation

struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    let displayText: String
    let speechText: String
    let answer: Int
    let table: Int
}

enum QuizData {
    private static let readings = ["", "いち", "に", "さん", "よん", "ご", "ろく", "なな", "はち", "きゅう"]

    static let allQuestions: [QuizQuestion] = (1...9).flatMap { left in
        (1...9).map { right in
            QuizQuestion(
                displayText: "\(left) × \(right) = ?",
                speechText: "\(readings[left])、かける、\(readings[right])、は？",
                answer: left * right,
                table: left
            )
        }
    }

    static func questions(forTable table: Int) -> [QuizQuestion] {
        allQuestions.filter { $0.table == table }
    }
}
