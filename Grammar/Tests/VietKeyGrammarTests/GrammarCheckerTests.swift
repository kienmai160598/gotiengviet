import Foundation
import Testing
import VietKeyGrammar

@Suite struct GrammarCheckerTests {
    static let checker = GrammarChecker()

    @Test func flagsAgreementWithAFix() throws {
        let text = "He go to school every day."
        let issues = try Self.checker.check(text: text)
        #expect(issues.count == 1)
        let issue = try #require(issues.first)
        #expect(Self.substring(text, issue) == "go")
        #expect(issue.replacements.first == "goes")
    }

    @Test(arguments: [
        "He goes to school every day.",
        "Can you check the logs on the staging server?",
        "The useEffect hook reruns when the deps array changes.",
        "Team bên em deploy xong rồi.",
        "Hôm nay trời đẹp quá, mình đi cà phê nhé.",
    ])
    func acceptsCorrectEnglishAndVietnamese(text: String) throws {
        #expect(try Self.checker.check(text: text).isEmpty)
    }

    @Test func rangesAreUTF16() throws {
        let text = "Đẹp quá 😀 she don't like it."
        let issue = try #require(try Self.checker.check(text: text).first)
        #expect(Self.substring(text, issue) == "don't")
    }

    @Test func overlappingLintsCollapseToOne() throws {
        let issues = try Self.checker.check(text: "The informations are wrong.")
        #expect(issues.count == 1)
        #expect(issues.first?.replacements.first == "information")
    }

    private static func substring(_ text: String, _ issue: GrammarIssue) -> String {
        (text as NSString).substring(with: NSRange(location: Int(issue.location), length: Int(issue.length)))
    }
}
