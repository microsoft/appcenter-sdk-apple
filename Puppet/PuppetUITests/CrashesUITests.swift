import XCTest

class CrashesUITests: XCTestCase {
  private var app : XCUIApplication?;
  private let CrashesCellIndex : UInt = 1;

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app = XCUIApplication();
    app?.launch();

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back)
    if let mobileCenterButton : XCUIElement = app?.switches["Set Enabled"] {
      if (mobileCenterButton.value as! String == "0") {
        mobileCenterButton.tap();
      }
    }
  }

  func testCrashes() {
    guard let `app` = app else {
      XCTFail();
      return;
    }

    // Go to crashes page and find "Set Enabled" button
    app.tables.cells.element(boundBy: CrashesCellIndex).tap();
    let crashesButton : XCUIElement = app.switches.element(boundBy: 0);

    // Service should be enabled by default
    XCTAssertEqual("1", crashesButton.value as! String);

    // Disable service
    crashesButton.tap();

    // Button is disabled
    XCTAssertEqual("0", crashesButton.value as! String);

    // Go back to start page
    app.buttons["Mobile Center"].tap();
    let mobileCenterButton : XCUIElement = app.switches.element(boundBy: 0);

    // SDK should be enabled
    XCTAssertEqual("1", mobileCenterButton.value as! String);

    // Disable SDK
    mobileCenterButton.tap();

    // Go to crash page again
    app.cells.element(boundBy: CrashesCellIndex).tap();

    // Button should be disabled
    XCTAssertEqual("0", crashesButton.value as! String);

    // Go back and enable SDK
    app.buttons["Mobile Center"].tap();

    // Enable SDK
    mobileCenterButton.tap();

    // Go to crashes page
    app.tables.cells.element(boundBy: CrashesCellIndex).tap();

    // Service should be enabled
    XCTAssertEqual("1", crashesButton.value as! String);
  }
}
