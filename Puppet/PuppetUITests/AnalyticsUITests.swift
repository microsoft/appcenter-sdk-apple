import XCTest

class AnalyticsUITests: XCTestCase {
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

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

    guard let `app` = app else {
      return;
    }

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let mobileCenterButton : XCUIElement = app.switches["Set Enabled"];
    if (mobileCenterButton.value as! String == "0") {
      mobileCenterButton.tap();
    }

    // Enable Analytics
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();
    let analyticsButton : XCUIElement = app.switches["Set Enabled"];
    if (analyticsButton.value as! String == "0") {
      analyticsButton.tap();
    }

    // Go back
    app.buttons["Mobile Center"].tap();
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
    app.buttons["Mobile Center"].tap();
    let mobileCenterButton : XCUIElement = app.switches.element(boundBy: 0);

    // SDK should be enabled.
    XCTAssertEqual("1", mobileCenterButton.value as! String);

    // Disable SDK.
    mobileCenterButton.tap();

    // Go to analytics page.
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Button should be disabled.
    XCTAssertEqual("0", analyticsButton.value as! String);

    // Go back and enable SDK.
    app.buttons["Mobile Center"].tap();

    // Enable SDK.
    mobileCenterButton.tap();

    // Go to analytics page.
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Service should be enabled.
    XCTAssertEqual("1", analyticsButton.value as! String);
  }

  func testTrackEvent() {
    guard let `app` = app else {
      XCTFail();
      return;
    }

    // Go to analytics page
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Track event
    self.trackEvent(withProps: 0);

    // Go to result page
    app.tables.cells.element(boundBy: 4).tap();

    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil);
    let propNumExp = expectation(for: NSPredicate(format: "label = '0'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil);
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil);

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 15);
  }

  func testTrackEventWithOneProps() {
    guard let `app` = app else {
      XCTFail();
      return;
    }

    // Go to analytics page
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Track event with one property
    self.trackEvent(withProps: 1);

    // Go to result page
    app.tables.cells.element(boundBy: 4).tap();

    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil);
    let propNumExp = expectation(for: NSPredicate(format: "label = '1'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil);
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil);

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 5);
  }

  func testTrackEventWithTooMuchProps() {
    guard let `app` = app else {
      XCTFail();
      return;
    }

    // Go to analytics page
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Track event with seven properties
    self.trackEvent(withProps: 7);

    // Go to result page
    app.tables.cells.element(boundBy: 4).tap();

    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil);
    let propNumExp = expectation(for: NSPredicate(format: "label = '5'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil);
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil);

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 5);
  }

  func testTrackEventWithDisabledAnalytics() {
    guard let `app` = app else {
      XCTFail();
      return;
    }

    // Go to analytics page
    app.tables.cells.element(boundBy: AnalyticsCellIndex).tap();

    // Disable service
    app.switches.element(boundBy: 0).tap();

    // Track event
    self.trackEvent(withProps: 0);

    // Go to result page
    app.tables.cells.element(boundBy: 4).tap();

    let eventNameExp = expectation(for: NSPredicate(format: "label != 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil);
    let propNumExp = expectation(for: NSPredicate(format: "label != '0'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSentExp = expectation(for: NSPredicate(format: "label != %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil);
    let didSendingExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil);
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil);

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 5);
  }

  private func trackEvent(withProps numOfProps : Int) {
    let trackEventCell : UInt = 0;
    let propCell : UInt = 2;
    for _ in 0..<numOfProps {
      app?.tables.cells.element(boundBy: propCell).tap();
    }
    app?.tables.cells.element(boundBy: trackEventCell).tap();
  }
}
