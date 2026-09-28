import Foundation
import FoundationModels

@Generable(description: "音声認識テキストから抽出した九九の答え")
struct ExtractedAnswer {
    @Guide(description: "認識された九九の答えとなる整数値（1から81の範囲など）。数字が特定できない場合はnil")
    var number: Int?
}

/// 音声認識テキストから九九の答えの数値を抽出し、表記揺れや誤認識を補正するクラス
final class AnswerExtractor: Sendable {
    nonisolated static let shared = AnswerExtractor()

    nonisolated init() {}

    /// 音声認識されたテキストから数値を抽出（FoundationModelsを使用し、揺らぎ・誤認識を補正）
    nonisolated func extractNumber(from text: String) async -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        do {
            let session = LanguageModelSession(
                instructions: """
                The person's locale is ja_JP.
                あなたは音声認識されたテキストから九九（かけ算）の答え（1から81の整数）を解釈・抽出するアシスタントです。
                ユーザーは九九の答えを音声で回答しています。
                音声認識の誤変換、表記揺れ、九九の唱え歌のフレーズ、口語表現、フィラーなどを考慮して、意図された整数値を抽出してください。

                【解釈例】
                - 算用数字・漢数字・ひらがな・カタカナ: 「24」「二十四」「にじゅうよん」「ニジュウヨン」 → 24
                - 音声の揺らぎ・読み分け: 「しじゅうに」「よんじゅうに」 → 42、「しちじゅうに」「ななじゅうに」 → 72
                - 九九の読み上げ全体: 「さんしじゅうに」 → 12、「ごしにじゅう」 → 20、「くくはちじゅういち」 → 81、「はっくななじゅうに」 → 72
                - 口語表現・フィラー: 「答えは24です」「たぶん16」「えーっと32かな」 → 24, 16, 32
                - 音声認識の同音異義語・誤認識: 「録」 → 6、「球」「急」 → 9、「蜂」 → 8、「世」「死」 → 4、「重」「十」 → 10
                - 数字と解釈できない場合や無関係な発言の場合は nil を返してください。
                """
            )
            let response = try await session.respond(
                to: "認識されたテキスト: \"\(trimmed)\"",
                generating: ExtractedAnswer.self
            )
            return response.content.number
        } catch {
            return nil
        }
    }
}
