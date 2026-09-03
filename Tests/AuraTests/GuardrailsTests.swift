import XCTest
@testable import Aura

final class GuardrailsTests: XCTestCase {
    func testSafeCommandClassification() {
        let guardrails = GuardrailsEngine()

        let safeEvaluation = guardrails.evaluateCommand("ls -la ~/Documents")
        XCTAssertTrue(safeEvaluation.isSafe)

        let gitStatusEvaluation = guardrails.evaluateCommand("git status")
        XCTAssertTrue(gitStatusEvaluation.isSafe)

        let findEvaluation = guardrails.evaluateCommand("find . -name '*.swift'")
        XCTAssertTrue(findEvaluation.isSafe)
    }

    func testDestructiveCommandClassification() {
        let guardrails = GuardrailsEngine()

        let rmEvaluation = guardrails.evaluateCommand("rm -rf /tmp/test")
        XCTAssertFalse(rmEvaluation.isSafe)
        if case .requiresConfirmation(let req) = rmEvaluation {
            XCTAssertEqual(req.riskLevel, .critical)
        } else {
            XCTFail("Expected requiresConfirmation for rm -rf")
        }

        let sudoEvaluation = guardrails.evaluateCommand("sudo reboot")
        XCTAssertFalse(sudoEvaluation.isSafe)

        let killEvaluation = guardrails.evaluateCommand("kill -9 12345")
        XCTAssertFalse(killEvaluation.isSafe)
    }
}
