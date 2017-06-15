import XCTest

class MobileCenterUITests: XCTestCase {
  private var app : XCUIApplication?;
  private let AnalyticsCellIndex : UInt = 0;

  private let kDidSentEventText : String = "Sent event occurred";
  private let kDidFailedToSendEventText : String = "Failed to send event occurred";
  private let kDidSendingEventText : String = "Sending event occurred";

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app = XCUIApplication();
    app?.launch();
    guard let `app` = app else {
      return;
    }

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let mobileCenterButton : XCUIElement = app.switches["Set Enabled"];
    if (mobileCenterButton.value as! String == "0") {
      mobileCenterButton.tap();
    }
  }

  func testEnableDisableSDK() {
    guard let `app` = app else {
      return;
    }
    let mobileCenterButton : XCUIElement = app.switches.element(boundBy: 0);

    // SDK should be enabled.
    XCTAssertEqual("1", mobileCenterButton.value as! String);

    // Disable SDK.
    mobileCenterButton.tap();

    // All services should be disabled.
    // Analytics.
    app.tables.cells.element(boundBy: 0).tap();
    XCTAssertEqual("0", app.switches.element(boundBy: 0).value as! String);
    app.buttons["Mobile Center"].tap();

    // Crashes.
    app.tables.cells.element(boundBy: 1).tap();
    XCTAssertEqual("0", app.switches.element(boundBy: 0).value as! String);
    app.buttons["Mobile Center"].tap();

    // Distribute.
    app.tables.cells.element(boundBy: 2).tap();
    let distributeSwitchButton : XCUIElement = app.switches.element(matching: XCUIElementType.switch, identifier: "Set Enabled");
    XCTAssertEqual("0", distributeSwitchButton.value as! String);
    app.buttons["Mobile Center"].tap();

    // Enable SDK.
    mobileCenterButton.tap();

    // All services should be enabled.
    // Analytics.
    app.tables.cells.element(boundBy: 0).tap();
    XCTAssertEqual("1", app.switches.element(boundBy: 0).value as! String);
    app.buttons["Mobile Center"].tap();

    // Crashes.
    app.tables.cells.element(boundBy: 1).tap();
    XCTAssertEqual("1", app.switches.element(boundBy: 0).value as! String);
    app.buttons["Mobile Center"].tap();

    // Distribute.
    app.tables.cells.element(boundBy: 2).tap();
    XCTAssertEqual("1", distributeSwitchButton.value as! String);
    app.buttons["Mobile Center"].tap();
  }

  func testMiscellaneousInfo() {
    guard let `app` = app else {
      return;
    }

    // Go to custom properties page.
    app.cells.element(boundBy: 3).tap();

    // Check custom properties. There shouldn't be any crash.
    for cellIndex in 0..<app.cells.count {
      app.cells.element(boundBy: cellIndex).tap();
    }
    app.buttons["Mobile Center"].tap();

    // Go to device info page.
    app.cells.element(boundBy: 4).tap();

    // Check device info. Device info shouldn't contain an empty info.
    for cellIndex in 0..<app.cells.count {
      let cell : XCUIElement = app.cells.element(boundBy: cellIndex);
      let deviceInfo : String = cell.staticTexts.element(boundBy: 1).label;
      XCTAssertNotNil(deviceInfo);
    }
    app.buttons["Mobile Center"].tap();

    // Check install id.
    let installIdCell : XCUIElement = app.cells.element(boundBy: 5);
    let installId : String = installIdCell.staticTexts.element(boundBy: 1).label;
    XCTAssertNotNil(UUID(uuidString: installId));

    // Check app secret.
    let appSecretCell : XCUIElement = app.cells.element(boundBy: 6);
    let appSecret : String = appSecretCell.staticTexts.element(boundBy: 1).label;
    XCTAssertNotNil(UUID(uuidString: appSecret));

    // Check log url.
    let logUrlCell : XCUIElement = app.cells.element(boundBy: 7);
    let logUrl : String = logUrlCell.staticTexts.element(boundBy: 1).label;
    XCTAssertNotNil(URL(string: logUrl));
  }
}
