import XCTest

/// Types on the real keyboard in the simulator, through the document proxy. Needs VietKey
/// to be the simulator's first keyboard (see README).
final class KeyboardUITests: XCTestCase {
    private var app: XCUIApplication!
    private var field: XCUIElement { app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch }

    @MainActor private func launch() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        field.tap()
    }

    @MainActor func testTelexBecomesVietnameseAtTheBoundary() {
        launch()
        type("vieetj nam ")
        XCTAssertEqual(field.value as? String, "Việt nam ")
    }

    @MainActor func testEnglishStaysEnglishAndBackspaceRestoresTheVietnamese() {
        launch()
        type("text ")
        XCTAssertEqual(field.value as? String, "Text ")
        tap("Delete")
        XCTAssertEqual(field.value as? String, "Tẽt")
    }

    @MainActor func testDeletingTheSpaceReopensTheWord() {
        launch()
        type("hoa ")
        tap("Delete")
        type("f ")
        XCTAssertEqual(field.value as? String, "Hòa ")
    }

    @MainActor func testDeletingAWordBeingTypedLeavesNothingBehind() {
        launch()
        type("ab")
        tap("Delete")
        tap("Delete")
        type("c ")
        XCTAssertEqual(field.value as? String, "C ")
    }

    /// The simulator's text view ignores a tap while a word is marked, so typing goes on.
    @MainActor func testTappingTheFieldMidWordNeverDuplicatesTheWord() {
        launch()
        type("hello ab")
        field.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 22, dy: 18)).tap()
        type("c ")
        let value = field.value as? String ?? ""
        XCTAssertEqual(value.components(separatedBy: "ab").count, 2, value)
    }

    /// Keeping the keys teaches the keyboard, so after the first run "car" no longer turns
    /// into "cả" and there is nothing to offer; either way the keys stay, and stay next time.
    @MainActor func testTheBarKeepsTheKeysAsTyped() {
        launch()
        type("car")
        let offer = app.buttons["“Car”"]
        if offer.waitForExistence(timeout: 2) {
            offer.tap()
        } else {
            type(" ")
        }
        type("car ")
        XCTAssertEqual(field.value as? String, "Car car ")
    }

    @MainActor func testTheBarOffersTheWordWithItsMarks() {
        launch()
        type("toi")
        let word = app.buttons["Tôi"]
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        word.tap()
        XCTAssertEqual(field.value as? String, "Tôi ")
    }

    @MainActor func testTheBarTypesAnEmojiBetweenWords() {
        launch()
        type("a ")
        app.buttons["😂"].tap()
        XCTAssertEqual(field.value as? String, "A 😂")
    }

    @MainActor func testTheEmojiPageTypesAnEmojiAndGoesBackToTheLetters() {
        launch()
        tap("Emoji")
        tap("😀")
        tap("ABC")
        type("a")
        tap("Emoji")
        tap("😃")
        XCTAssertEqual(field.value as? String, "😀a😃")
    }

    /// The gaps between key faces and the strip beside the outer keys belong to no key face.
    @MainActor func testATapBetweenKeysOrAtTheScreenEdgeStillTypes() {
        launch()
        key("g").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)).tap()
        key("q").coordinate(withNormalizedOffset: CGVector(dx: -0.05, dy: 0.5)).tap()
        key("p").coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        XCTAssertEqual(field.value as? String, "Gqp")
    }

    @MainActor func testShiftCapitalisesOneLetterAndADoubleTapLocksCapitals() {
        launch()
        type("ab ")
        tap("Shift")
        type("cd ")
        key("Shift").doubleTap()
        type("mn")
        XCTAssertEqual(field.value as? String, "Ab Cd MN")
    }

    @MainActor func testLeavingTheAppMidWordKeepsTheWordOnce() {
        launch()
        type("ab")
        XCUIDevice.shared.press(.home)
        app.activate()
        // Three times in ten the field reads empty just after the app comes back.
        wait(for: [expectation(for: NSPredicate(format: "value == %@", "Ab"), evaluatedWith: field)], timeout: 5)
    }

    @MainActor private func type(_ keys: String) {
        keys.forEach { tap($0 == " " ? "space" : String($0)) }
    }

    @MainActor private func tap(_ label: String) {
        key(label).tap()
    }

    @MainActor private func key(_ label: String) -> XCUIElement {
        let key = app.keys.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
        XCTAssertTrue(key.waitForExistence(timeout: 5), "no key \(label)")
        return key
    }
}
