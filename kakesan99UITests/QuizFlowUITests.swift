import XCTest

final class QuizFlowUITests: XCTestCase {
    @MainActor
    func testQuestionFlowReachesResult() throws {
        let app = XCUIApplication()
        app.launch()

        let askButton = app.buttons["もんだいを だす"]
        XCTAssertTrue(askButton.waitForExistence(timeout: 5))
        askButton.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons.matching(
            NSPredicate(format: "label IN {'OK', 'Allow', '許可'}")
        ).firstMatch
        if allowButton.waitForExistence(timeout: 3) {
            allowButton.tap()
            if allowButton.waitForExistence(timeout: 3) {
                allowButton.tap()
            }
        }

        let resultLabel = app.staticTexts["きこえた こたえ"]
        XCTAssertTrue(resultLabel.waitForExistence(timeout: 30), "読み上げと5秒受付を経て判定結果が表示されること")

        let nextButton = app.buttons["つぎの もんだい"]
        XCTAssertTrue(nextButton.exists)
    }
}
