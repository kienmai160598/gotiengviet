import Testing
import VietKeyCore

struct KeyRolloverTests {
    private var rollover = KeyRollover<Character>()
    private var typed = ""

    private mutating func down(_ key: Character) {
        if let held = rollover.interrupt() { typed.append(held) }
        rollover.hold(key)
    }

    private mutating func up(_ key: Character) {
        if rollover.lift(key) { typed.append(key) }
    }

    @Test mutating func aTapTypesWhenTheFingerLifts() {
        down("a")
        #expect(typed.isEmpty)
        up("a")
        #expect(typed == "a")
    }

    @Test mutating func overlappingFingersTypeInTheOrderTheyTouched() {
        down("n")
        down("j")
        up("j")
        up("n")
        #expect(typed == "nj")
    }

    @Test mutating func aKeyTypedByALaterTouchIsNotTypedAgainWhenItLifts() {
        down("a")
        down("b")
        up("a")
        #expect(typed == "a")
        up("b")
        #expect(typed == "ab")
    }

    @Test mutating func threeFingersKeepTheirOrder() {
        down("a")
        down("b")
        down("c")
        up("c")
        up("a")
        up("b")
        #expect(typed == "abc")
    }

    @Test mutating func aTouchOnAKeyThatActsAtOnceStillTypesTheHeldKeyFirst() {
        down("a")
        let typedFirst = rollover.interrupt()
        let typedAgain = rollover.lift("a")
        #expect(typedFirst == "a")
        #expect(!typedAgain)
    }
}
