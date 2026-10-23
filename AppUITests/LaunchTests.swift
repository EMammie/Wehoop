import XCTest

final class LaunchTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsTheFiveTabs() {
        let app = XCUIApplication()
        app.launchArguments = ["-WehoopFixtures"]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        for title in ["Scores", "Leaders", "Players", "Teams", "Favorites"] {
            XCTAssertTrue(tabBar.buttons[title].exists, "missing tab \(title)")
        }
        tabBar.buttons["Leaders"].tap()
        XCTAssertTrue(app.staticTexts["Stat leaders by category."].waitForExistence(timeout: 5))
    }
}
