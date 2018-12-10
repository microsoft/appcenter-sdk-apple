import XCTest

class AppCenterUITests : XCTestCase {

  private var app: XCUIApplication?

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    app = XCUIApplication()
    app?.launch()

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    guard let `app` = app else {
      return
    }
    let cell = app.cells.element(boundBy: 6)
    let text = cell.staticTexts.element(boundBy: 1)
    if (text.label == "Disabled") {
      press(button: .down, times: 6)
      XCUIRemote.shared().press(.select)
      press(button: .up, times: 6)
    }
  }

  func testEnableDisableSDK() {
    guard let `app` = app else {
      return
    }

    // Check App Center status.
    let mcCell = app.cells.element(boundBy: 6)
    let mcStatus = mcCell.staticTexts.element(boundBy: 1)
    XCTAssertTrue(mcStatus.label == "Enabled")

    // Disable App Center.
    press(button: .down, times: 6)
    XCUIRemote.shared().press(.select)
    XCTAssertTrue(mcStatus.label == "Disabled")

    // Check Analytics.
    press(button: .up, times: 6)
    XCUIRemote.shared().press(.select)
    let disabledButton = app.segmentedControls.buttons["Disabled"]
    XCTAssertTrue(disabledButton.isSelected)

    // Without this delay the app doesn't have time to go back and the test fails.
    sleep(1)

    // Go back.
    press(button: .menu, times: 1)

    // Without this delay the app doesn't have time to go back and the test fails.
    sleep(1)

    // Enable App Center.
    press(button: .down, times: 6)
    XCUIRemote.shared().press(.select)

    // Without this delay the app doesn't have time to go back and the test fails.
    sleep(1)

    XCTAssertTrue(mcStatus.label == "Enabled")

    // Check Analytics.
    press(button: .up, times: 6)
    XCUIRemote.shared().press(.select)


    // Without this delay the app doesn't have time to go back and the test fails.
    sleep(1)

    let enabledButton = app.segmentedControls.buttons["Enabled"]
    XCTAssertTrue(enabledButton.isSelected)
  }

  func testMiscellaneousInfo() {
    guard let `app` = app else {
      return
    }

    // Check install id.
    let installIdCell = app.cells.element(boundBy: 3)
    let installId : String = installIdCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(UUID(uuidString:installId))

    // Check app secret.
    let appSecretCell = app.cells.element(boundBy: 4)
    let appSecret : String = appSecretCell.staticTexts.element(boundBy: 1).label
    XCTAssertTrue(appSecret.isEqual("Internal"))

    // TODO: Uncomment when app secret is moved from internal to public.
    //XCTAssertNotNil(UUID(uuidString:appSecret))

    // Check log url.
    let logUrlCell = app.cells.element(boundBy: 5)
    let logUrl : String = logUrlCell.staticTexts.element(boundBy: 1).label
    XCTAssertTrue(logUrl.isEqual("Internal"))

    // TODO: Uncomment when log url is moved from internal to public.
    //XCTAssertNotNil(URL(string:logUrl))
  }

  private func press(button : XCUIRemoteButton, times : Int) {
    for _ in 0...times {
      XCUIRemote.shared().press(button)
    }
  }
}
