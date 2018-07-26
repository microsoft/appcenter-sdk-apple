import XCTest

class AnalyticsUITests: XCTestCase {

  private var app : XCUIApplication?
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
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    app.tables["Analytics"].staticTexts["Results"].tap()
    
    let resultsTable = app.tables["Analytics Result"]
    let nameExp = expectation(for: NSPredicate(format: "label = %@", "myEvent"),
                              evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 1),
                              handler: nil)
    let propsCountExp = expectation(for: NSPredicate(format: "label = '0'"),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 5).staticTexts.element(boundBy: 1),
                                    handler: nil)
    let statusExp = expectation(for: NSPredicate(format: "label = %@", "Succeeded"),
                                evaluatedWith: resultsTable.cells.element(boundBy: 6).staticTexts.element(boundBy: 1),
                                handler: nil)
    wait(for: [nameExp, propsCountExp, statusExp], timeout: timeout)
    #endif
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
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    app.tables["Analytics"].staticTexts["Results"].tap()
    
    let resultsTable = app.tables["Analytics Result"]
    let nameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                              evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 1),
                              handler: nil)
    let propsCountExp = expectation(for: NSPredicate(format: "label = '1'"),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 5).staticTexts.element(boundBy: 1),
                                    handler: nil)
    let statusExp = expectation(for: NSPredicate(format: "label = 'Succeeded'"),
                                evaluatedWith: resultsTable.cells.element(boundBy: 6).staticTexts.element(boundBy: 1),
                                handler: nil)
    wait(for: [nameExp, propsCountExp, statusExp], timeout: timeout)
    #endif
  }

  func testTrackEventWithTooMuchProps() {
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

    // Track event with seven properties.
    self.trackEvent(name: "myEvent", propertiesCount: 23)

    // Go to result page.
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    app.tables["Analytics"].staticTexts["Results"].tap()
    
    let resultsTable = app.tables["Analytics Result"]
    let nameExp = expectation(for: NSPredicate(format: "label = 'myEvent'"),
                              evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 1),
                              handler: nil)
    let propsCountExp = expectation(for: NSPredicate(format: "label = '20'"),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 5).staticTexts.element(boundBy: 1),
                                    handler: nil)
    let statusExp = expectation(for: NSPredicate(format: "label = 'Succeeded'"),
                                evaluatedWith: resultsTable.cells.element(boundBy: 6).staticTexts.element(boundBy: 1),
                                handler: nil)
    wait(for: [nameExp, propsCountExp, statusExp], timeout: timeout)
    #endif
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
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    app.tables["Analytics"].staticTexts["Results"].tap()
    
    let resultsTable = app.tables["Analytics Result"]
    let nameExp = expectation(for: NSPredicate(format: "label = ' '"),
                              evaluatedWith: resultsTable.cells.element(boundBy: 3).staticTexts.element(boundBy: 1),
                              handler: nil)
    let propsCountExp = expectation(for: NSPredicate(format: "label = '0'"),
                                    evaluatedWith: resultsTable.cells.element(boundBy: 5).staticTexts.element(boundBy: 1),
                                    handler: nil)
    let statusExp = expectation(for: NSPredicate(format: "label = ' '"),
                                evaluatedWith: resultsTable.cells.element(boundBy: 6).staticTexts.element(boundBy: 1),
                                handler: nil)
    wait(for: [nameExp, propsCountExp, statusExp], timeout: timeout)
    #endif
  }

  private func trackEvent(name: String, propertiesCount: UInt) {
    guard let analyticsTable = app?.tables["Analytics"] else {
      XCTFail()
      return
    }
    
    // Add properties.
    for _ in 0..<propertiesCount {
      analyticsTable.staticTexts["Add Property"].tap()
    }
    
    // Set name.
    let eventName = analyticsTable.cell(containing: "Event Name").textFields.element
    eventName.clearAndTypeText(name)
    
    // Send.
    analyticsTable.buttons["Track Event"].tap()
  }
}
