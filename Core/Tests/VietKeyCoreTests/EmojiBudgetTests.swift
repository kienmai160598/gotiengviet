import Testing
@testable import VietKeyCore

struct EmojiBudgetTests {
    @Test func drawsWhileMemoryIsLeft() {
        let budget = EmojiBudget { EmojiBudget.floor + 1 }
        #expect(budget.allows("😀"))
    }

    @Test func drawsWhenTheProcessHasNoLimit() {
        let budget = EmojiBudget { 0 }
        #expect(budget.allows("😀"))
    }

    @Test func stopsDrawingNewEmojiNearTheLimitButKeepsTheOnesDrawn() {
        var left = EmojiBudget.floor + 1
        let budget = EmojiBudget { left }
        #expect(budget.allows("😀"))
        left = EmojiBudget.floor
        #expect(!budget.allows("😂"))
        #expect(budget.allows("😀"))
    }

    @Test func drawsAgainOnceMemoryComesBack() {
        var left = EmojiBudget.floor
        let budget = EmojiBudget { left }
        #expect(!budget.allows("😂"))
        left = EmojiBudget.floor * 2
        #expect(budget.allows("😂"))
    }
}
