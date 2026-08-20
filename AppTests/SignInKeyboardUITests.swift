import XCTest

/// Answers one question, the one that got 1.0 (22) refused:
/// **does a keyboard appear on the sign-in screen, and does typing reach the field?**
///
/// Apple reviewed on an iPad Air and reported "the keyboard was not displayed,
/// and we could not enter the demo account". Their screenshot showed the field
/// focused and the keyboard's accessory bar drawn, with plain black where the
/// keys belong — the software keyboard was asked for, given space, and never
/// rendered. In 1.0 (22) those fields were a web page inside a system-hosted
/// sheet, which is where that breaks.
///
/// ⚠️ What this test can and cannot prove:
///   • It CAN prove the native form focuses its first field on its own and that
///     typing lands. That code was written today and nothing had exercised it.
///   • It CANNOT fully stand in for a real iPad. A simulator's keyboard is not
///     the device's, and the failure Apple hit is a rendering fault. A green run
///     here raises confidence; it does not replace one real iPad.
final class SignInKeyboardUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testKeyboardComesUpAndTypingLands() {
        let app = XCUIApplication()
        // Nothing is signed in on a fresh simulator, so the app opens straight
        // onto the sign-in form.
        app.launch()

        // Queried positionally rather than by label: the placeholders are Hebrew,
        // and a query that depends on them fails for the wrong reason. The screen
        // has exactly one plain text field (the address); the other is secure.
        let email = app.textFields.firstMatch
        XCTAssertTrue(
            email.waitForExistence(timeout: 30),
            "the sign-in form never appeared — if FIREBASE_API_KEY was empty the app "
            + "falls back to the old browser button and there is no field to find"
        )

        // The form focuses this field as it appears, so the keyboard should be up
        // with nothing tapped. That is the whole point on iPad: it removes the tap
        // that failed for the reviewer.
        let keyboard = app.keyboards.firstMatch
        let cameUpByItself = keyboard.waitForExistence(timeout: 15)

        if !cameUpByItself {
            // Not fatal on its own — fall back to the ordinary interaction and
            // report which of the two failed, because they mean different things.
            email.tap()
            XCTAssertTrue(
                keyboard.waitForExistence(timeout: 15),
                "no keyboard, even after tapping the field. This is exactly what "
                + "Apple reported on iPad Air."
            )
            XCTFail("the keyboard needed a tap — auto-focus did not take effect")
        }

        email.typeText("reviewer@example.com")
        XCTAssertEqual(
            email.value as? String,
            "reviewer@example.com",
            "the keyboard was present but the characters never reached the field"
        )
    }
}
