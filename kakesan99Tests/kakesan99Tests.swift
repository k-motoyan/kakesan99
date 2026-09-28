import Testing
@testable import kakesan99

struct kakesan99Tests {

    @Test func testAsyncExtractNumber() async {
        let extractor = AnswerExtractor()
        let result1 = await extractor.extractNumber(from: "24")
        #expect(result1 == 24)

        let result2 = await extractor.extractNumber(from: "二十四")
        #expect(result2 == 24)

        let result3 = await extractor.extractNumber(from: "")
        #expect(result3 == nil)
    }

    @Test func testVoiceFluctuationExtraction() async {
        let extractor = AnswerExtractor()
        // ひらがな・カタカナ・口語表現・九九フレーズなどの音声揺らぎの抽出テスト
        let hiraganaResult = await extractor.extractNumber(from: "にじゅうよん")
        #expect(hiraganaResult == 24)

        let phraseResult = await extractor.extractNumber(from: "答えは36です")
        #expect(phraseResult == 36)

        let kukuPhraseResult = await extractor.extractNumber(from: "さんしじゅうに")
        #expect(kukuPhraseResult == 12)
    }
}
