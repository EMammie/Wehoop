import XCTest

/// The Scores tab in fixture mode (`-WehoopFixtures`, no network): each league's golden game
/// tips off at launch and its score moves on the list; the league switch and a tapped card
/// lead to that league's games and the game screen.
final class ScoresUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func cards(_ app: XCUIApplication, containing text: String) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier == 'score-card' AND label CONTAINS %@", text))
    }

    @MainActor
    func testScoresListUpdatesSwitchesLeagueAndOpensAGame() {
        let app = XCUIApplication()
        app.launchArguments = ["-WehoopFixtures"]
        app.launch()

        // Today's WNBA game, labelled as the replay it is.
        let liberty = cards(app, containing: "New York Liberty").firstMatch
        XCTAssertTrue(liberty.waitForExistence(timeout: 15), "no WNBA score card")
        XCTAssertTrue(liberty.label.hasPrefix("Replay."), liberty.label)
        // It tips off at launch: within a scoreboard tick it is in the Live section.
        XCTAssertTrue(app.staticTexts["Live"].waitForExistence(timeout: 10), "no Live section")

        // The scoreboard channel moves it: the card's label changes without a reload.
        let before = liberty.label
        let moved = expectation(for: NSPredicate(format: "label != %@", before), evaluatedWith: liberty)
        wait(for: [moved], timeout: 15)

        // The league switch shows the next league's games (leagues come from the data).
        app.buttons["NCAAW"].tap()
        let spartans = cards(app, containing: "Michigan State Spartans")
        XCTAssertTrue(spartans.firstMatch.waitForExistence(timeout: 10), "no NCAAW score card")
        XCTAssertFalse(cards(app, containing: "New York Liberty").firstMatch.exists)

        // A tapped card opens the game screen, which carries the same replay note.
        spartans.firstMatch.tap()
        let note = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'replayed at real-time speed'")).firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 15), "the game screen did not open")
    }
}
