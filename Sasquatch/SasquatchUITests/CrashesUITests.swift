import XCTest

class CrashesUITests: XCTestCase {
  private var app : XCUIApplication?

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app = XCUIApplication()
    app?.launch()
    guard let `app` = app else {
      return;
    }
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    handleSystemAlert()

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let appCenterButton = app.tables["App Center"].switches["Set Enabled"]
    if (!appCenterButton.boolValue) {
      appCenterButton.tap()
    }
  }

  func testCrashes() {
    guard let `app` = app else {
      XCTFail();
      return
    }

    // Go to crashes page and find "Set Enabled" button.
    app.tabBars.buttons["Crashes"].tap()
    let crashesButton = app.tables["Crashes"].switches["Set Enabled"]

    // Service should be enabled by default.
    XCTAssertTrue(crashesButton.boolValue)

    // Disable service.
    crashesButton.tap()

    // Button is disabled.
    XCTAssertFalse(crashesButton.boolValue)

    // Go back to start page.
    app.tabBars.buttons["App Center"].tap()
    let appCenterButton = app.switches.element(boundBy: 0)

    // SDK should be enabled.
    XCTAssertTrue(appCenterButton.boolValue)

    // Disable SDK.
    appCenterButton.tap()

    // Go to crash page again.
    app.tabBars.buttons["Crashes"].tap()

    // Button should be disabled.
    XCTAssertFalse(crashesButton.boolValue)

    // Go back and enable SDK.
    app.tabBars.buttons["App Center"].tap()

    // Enable SDK.
    appCenterButton.tap()

    // Go to crashes page.
    app.tabBars.buttons["Crashes"].tap()

    // Service should be enabled.
    XCTAssertTrue(crashesButton.boolValue)
  }
}
