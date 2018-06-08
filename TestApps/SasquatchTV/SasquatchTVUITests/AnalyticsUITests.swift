import XCTest;

class AnalyticsCUITests : XCTestCase {

  private var app : XCUIApplication?;

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false;

    app = XCUIApplication();
    app?.launch();

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    guard let `app` = app else {
      return;
    }
    let cell = app.cells.element(boundBy: 4);
    let texts = cell.children(matching: .staticText);
    if (texts.element(boundBy: 1).label == "Disabled") {
      press(button: .down, times: 4);
      XCUIRemote.shared().press(.select);
      press(button: .up, times: 4);
    }
  }

  func testAnalytics() {
    guard let `app` = app else {
      return;
    }

    // Go to Analytics page.
    XCUIRemote.shared().press(.select);

    // Check status.
    let enabledButton = app.segmentedControls.buttons["Enabled"];
    let disabledButton = app.segmentedControls.buttons["Disabled"];

    XCTAssertTrue(enabledButton.isSelected);
    XCTAssertFalse(disabledButton.isSelected);

    // Select analytics status control.
    press(button: .down, times: 4);

    // Disable Analytics.
    XCUIRemote.shared().press(.right);
    XCUIRemote.shared().press(.select);

    // Go back.
    XCUIRemote.shared().press(.menu);

    // Check SDK status.
    let cell = app.cells.element(boundBy: 4);
    let texts = cell.children(matching: .staticText);
    XCTAssertTrue(texts.element(boundBy: 1).label == "Enabled");

    // Select App Center status cell.
    press(button: .down, times: 4);

    // Disable App Center.
    XCUIRemote.shared().press(.select);

    // Go to Analytics page.
    press(button: .up, times: 4);
    XCUIRemote.shared().press(.select);

    // Check Analytics status.
    XCTAssertFalse(enabledButton.isSelected);
    XCTAssertTrue(disabledButton.isSelected);

    // Without this delay the app doesn't have time to go back and the test fails.
    sleep(1);

    // Go back and enable App Center.
    XCUIRemote.shared().press(.menu);

    // Without this delay the app doesn't have time to go down and the test fails.
    sleep(1);

    press(button: .down, times: 4);
    XCUIRemote.shared().press(.select);

    // Go to Analytics page.
    press(button: .up, times: 4);
    XCUIRemote.shared().press(.select);

    // Check Analytics status.
    XCTAssertTrue(enabledButton.isSelected);
    XCTAssertFalse(disabledButton.isSelected);
  }

  private func press(button : XCUIRemoteButton, times : Int) {
    for _ in 0...times {
      XCUIRemote.shared().press(button);
    }
  }
}
