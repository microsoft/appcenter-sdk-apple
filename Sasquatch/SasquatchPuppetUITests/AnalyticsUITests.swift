import XCTest

class AnalyticsUITests: XCTestCase {
  private var app : XCUIApplication?

  private let kDidSentEventText : String = "Sent event occurred"
  private let kDidFailedToSendEventText : String = "Failed to send event occurred"
  private let kDidSendingEventText : String = "Sending event occurred"
  
  private let timeout : TimeInterval = 10

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
    handleSystemAlert()
    
    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let appCenterButton = app.tables["App Center"].switches["Set Enabled"]
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
    app.tabBars.buttons["Analytics"].tap()
    let analyticsButton = app.tables["Analytics"].switches["Set Enabled"]

    // Service should be enabled by default.
    XCTAssertTrue(analyticsButton.boolValue)

    // Disable service.
    analyticsButton.tap()

    // Button is disabled.
    XCTAssertFalse(analyticsButton.boolValue)

    // Go back to start page and disable SDK.
    app.tabBars.buttons["App Center"].tap()
    let appCenterButton = app.tables["App Center"].switches["Set Enabled"]

    // SDK should be enabled.
    XCTAssertTrue(appCenterButton.boolValue)

    // Disable SDK.
    appCenterButton.tap()

    // Go to analytics page.
    app.tabBars.buttons["Analytics"].tap()

    // Button should be disabled.
    XCTAssertFalse(analyticsButton.boolValue)

    // Go back and enable SDK.
    app.tabBars.buttons["App Center"].tap()

    // Enable SDK.
    appCenterButton.tap()

    // Go to analytics page.
    app.tabBars.buttons["Analytics"].tap()

    // Service should be enabled.
    XCTAssertTrue(analyticsButton.boolValue)
  }

  func testTrackEvent() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tabBars.buttons["Analytics"].tap()
    
    // Make sure the module is enabled.
    let analyticsButton = app.tables["Analytics"].switches["Set Enabled"]
    if (!analyticsButton.boolValue) {
      analyticsButton.tap()
    }

    // Track event.
    self.trackEvent(name: "myEvent", propertiesCount: 0)

    // Go to result page.
    app.buttons["Results"].tap()

    let resultsTable = app.tables["Analytics Result"]
    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: resultsTable.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label = '0'"),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidFailedToSendEventText),
                                evaluatedWith: resultsTable.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: timeout)
  }

  func testTrackEventWithOneProps() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tabBars.buttons["Analytics"].tap()

    // Make sure the module is enabled.
    let analyticsButton = app.tables["Analytics"].switches["Set Enabled"]
    if (!analyticsButton.boolValue) {
      analyticsButton.tap()
    }

    // Track event with one property.
    self.trackEvent(name: "myEvent", propertiesCount: 1)

    // Go to result page.
    app.buttons["Results"].tap()

    let resultsTable = app.tables["Analytics Result"]
    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: resultsTable.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label = '1'"),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidFailedToSendEventText),
                                evaluatedWith: resultsTable.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: timeout)
  }

  func testTrackEventWithTooMuchProps() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tabBars.buttons["Analytics"].tap()

    // Track event with seven properties.
    self.trackEvent(name: "myEvent", propertiesCount: 7)

    // Go to result page.
    app.buttons["Results"].tap()

    let resultsTable = app.tables["Analytics Result"]
    let eventNameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                                   evaluatedWith: resultsTable.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label = '5'"),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label = %@", kDidSentEventText),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label = %@", kDidSendingEventText),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidFailedToSendEventText),
                                evaluatedWith: resultsTable.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: timeout)
  }

  func testTrackEventWithDisabledAnalytics() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to analytics page.
    app.tabBars.buttons["Analytics"].tap()
    
    // Disable service.
    let analyticsButton = app.tables["Analytics"].switches["Set Enabled"]
    if (analyticsButton.boolValue) {
      analyticsButton.tap()
    }

    // Track event.
    self.trackEvent(name: "myEvent", propertiesCount: 0)

    // Go to result page.
    app.buttons["Results"].tap()

    let resultsTable = app.tables["Analytics Result"]
    let eventNameExp = expectation(for: NSPredicate(format: "label != 'myEvent'"),
                                   evaluatedWith: resultsTable.cells.element(boundBy: 0).staticTexts.element(boundBy: 0),
                                   handler: nil)
    let propNumExp = expectation(for: NSPredicate(format: "label != '0'"),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 1).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSentExp = expectation(for: NSPredicate(format: "label != %@", kDidSentEventText),
                                 evaluatedWith: resultsTable.cells.element(boundBy: 2).staticTexts.element(boundBy: 0),
                                 handler: nil)
    let didSendingExp = expectation(for: NSPredicate(format: "label != %@", kDidSendingEventText),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 0),
                                    handler: nil)
    let failedExp = expectation(for: NSPredicate(format: "label != %@", kDidFailedToSendEventText),
                                evaluatedWith: resultsTable.cells.element(boundBy: 4).staticTexts.element(boundBy: 0),
                                handler: nil)

    wait(for: [eventNameExp, propNumExp, didSentExp, didSendingExp, failedExp], timeout: timeout)
  }

  private func trackEvent(name : String, propertiesCount : UInt) {
    guard let analyticsTable = app?.tables["Analytics"] else {
      XCTFail()
      return
    }
    
    // Add properties.
    for i in 0..<propertiesCount {
      analyticsTable.staticTexts["Add Property"].tap()
      let propertyCell = analyticsTable.cells.containing(.textField, identifier: "Key").element(boundBy: i)
      propertyCell.textFields["Key"].clearAndTypeText("key\(i)")
      propertyCell.textFields["Value"].clearAndTypeText("value\(i)")
    }
    
    // Set name.
    let eventName = analyticsTable.cell(containing: "Event Name").textFields.element
    eventName.clearAndTypeText(name)
    
    // Send.
    analyticsTable.buttons["Track Event"].tap()
  }
}
