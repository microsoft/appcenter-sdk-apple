import XCTest

class AnalyticsUITests: XCTestCase {
  private var app : XCUIApplication?

  private let kDidSentEventText : String = "Sent event occurred"
  private let kDidFailedToSendEventText : String = "Failed to send event occurred"
  private let kDidSendingEventText : String = "Sending event occurred"

  override func setUp() {
    super.setUp()

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    app = XCUIApplication()
    app?.launch()
    guard let `app` = app else {
      return
    }

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let appCenterButton : XCUIElement = app.switches["Set Enabled"]
    if (!appCenterButton.boolValue) {
      appCenterButton.tap()
    }
  }

  func testAnalytics() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page and find "Set Enabled" button.
    app.tables["App Center"].staticTexts["Analytics"].tap()
    let analyticsButton : XCUIElement = app.tables["Analytics"].switches["Set Enabled"]

    // Service should be enabled by default.
    XCTAssertTrue(analyticsButton.boolValue)

    // Disable service.
    analyticsButton.tap()

    // Button is disabled.
    XCTAssertFalse(analyticsButton.boolValue)

    // Go back to start page and disable SDK.
    app.buttons["App Center"].tap()
    let appCenterButton : XCUIElement = app.switches["Set Enabled"]

    // SDK should be enabled.
    XCTAssertTrue(appCenterButton.boolValue)

    // Disable SDK.
    appCenterButton.tap()

    // Go to analytics page.
    app.tables["App Center"].staticTexts["Analytics"].tap()

    // Button should be disabled.
    XCTAssertFalse(appCenterButton.boolValue)

    // Go back and enable SDK.
    app.buttons["App Center"].tap()

    // Enable SDK.
    appCenterButton.tap()

    // Go to analytics page.
    app.tables["App Center"].staticTexts["Analytics"].tap()

    // Service should be enabled.
    XCTAssertTrue(analyticsButton.boolValue)
  }

  func testTrackEvent() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tables["App Center"].staticTexts["Analytics"].tap()

    // Track event.
    self.trackEvent(name: "myEvent", propertiesCount: 0)

    // Go to result page.
    app.buttons["Results"].tap()

    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label = '0'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 15)
  }

  func testTrackEventWithOneProps() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tables["App Center"].staticTexts["Analytics"].tap()

    // Track event with one property.
    self.trackEvent(name: "myEvent", propertiesCount: 1)

    // Go to result page.
    app.buttons["Results"].tap()

    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label = '1'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 5)
  }

  func testTrackEventWithTooMuchProps() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tables["App Center"].staticTexts["Analytics"].tap()

    // Track event with seven properties.
    self.trackEvent(name: "myEvent", propertiesCount: 7)

    // Go to result page.
    app.buttons["Results"].tap()

    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label = '5'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 5)
  }

  func testTrackEventWithDisabledAnalytics() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tables["App Center"].staticTexts["Analytics"].tap()

    // Disable service.
    app.switches.element(boundBy: 0).tap()

    // Track event.
    self.trackEvent(name: "myEvent", propertiesCount: 0)

    // Go to result page.
    app.buttons["Results"].tap()

    let eventNameExp = expectation(for: NSPredicate(format: "label != 'myEvent'"),
                                   evaluatedWith: app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label != '0'"),
                                 evaluatedWith: app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label != %@", kDidSentEventText),
                                 evaluatedWith: app.tables.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                    evaluatedWith: app.tables.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                evaluatedWith: app.tables.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: 5)
  }

  private func trackEvent(name : String, propertiesCount : Int) {
    guard let analyticsTable = app?.tables["Analytics"] else {
      XCTFail()
      return
    }
    
    /*for _ in 0..<numOfProps {
     app?.tables.cells.element(boundBy: propCell).tap()
     }*/
    
    // Set name.
    let eventName = analyticsTable.cell(containing: "Event Name").textFields.element
    eventName.clearAndTypeText(name)
    
    // Send.
    analyticsTable.buttons["Track Event"].tap()
  }
}
