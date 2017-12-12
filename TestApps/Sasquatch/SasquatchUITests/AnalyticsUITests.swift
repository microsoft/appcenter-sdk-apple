import XCTest

class AnalyticsUITests: XCTestCase {
  private var app : XCUIApplication?;
  private let AnalyticsCellIndex : UInt = 0;

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app = XCUIApplication();
    app?.launch();

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    if let appCenterButton : XCUIElement = app?.switches["Set Enabled"] {
      if (appCenterButton.value as! String == "0") {
        appCenterButton.tap();
      }
    }
  }

  func testAnalytics() {
    guard let `app` = app else {
      XCTFail();
      return;
    }

    // Go to analytics page and find "Set Enabled" button.
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();
    let analyticsButton : XCUIElement = app.switches.element(boundBy: 0);

    // Service should be enabled by default.
    XCTAssertEqual("1", analyticsButton.value as! String);

    // Disable service.
    analyticsButton.tap();

    // Button is disabled.
    XCTAssertEqual("0", analyticsButton.value as! String);

    // Go back to start page and disable SDK.
    app.buttons["App Center"].tap();
    let appCenterButton : XCUIElement = app.switches.element(boundBy: 0);

    // SDK should be enabled.
    XCTAssertEqual("1", appCenterButton.value as! String);

    // Disable SDK.
    appCenterButton.tap();

    // Go to analytics page.
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Button should be disabled.
    XCTAssertEqual("0", analyticsButton.value as! String);

    // Go back and enable SDK.
    app.buttons["App Center"].tap();

    // Enable SDK.
    appCenterButton.tap();

    // Go to analytics page.
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Service should be enabled.
    XCTAssertEqual("1", analyticsButton.value as! String);
  }
}
