import XCTest

class AppCenterUITests: XCTestCase {
  private var app : XCUIApplication?

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

    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let appCenterButton : XCUIElement = app.switches["Set Enabled"]
    if (!appCenterButton.boolValue) {
      appCenterButton.tap()
    }
  }

  func testEnableDisableSDK() {
    guard let `app` = app else {
      XCTFail()
      return
    }
    let appCenterButton : XCUIElement = app.switches["Set Enabled"]

    // SDK should be enabled.
    XCTAssertTrue(appCenterButton.boolValue)

    // Disable SDK.
    appCenterButton.tap()

    // All services should be disabled.
    // Analytics.
    app.tables["App Center"].staticTexts["Analytics"].tap()
    XCTAssertFalse(app.tables["Analytics"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()

    // Crashes.
    app.tables["App Center"].staticTexts["Crashes"].tap()
    XCTAssertFalse(app.tables["Crashes"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()

    // Distribute.
    app.tables["App Center"].staticTexts["Distribute"].tap()
    XCTAssertFalse(app.tables["Distribute"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()
    
    // Push.
    app.tables["App Center"].staticTexts["Push"].tap()
    XCTAssertFalse(app.tables["Push"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()

    // Enable SDK.
    appCenterButton.tap()

    // All services should be enabled.
    // Analytics.
    app.tables["App Center"].staticTexts["Analytics"].tap()
    XCTAssertTrue(app.tables["Analytics"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()

    // Crashes.
    app.tables["App Center"].staticTexts["Crashes"].tap()
    XCTAssertTrue(app.tables["Crashes"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()

    // Distribute.
    app.tables["App Center"].staticTexts["Distribute"].tap()
    XCTAssertTrue(app.tables["Distribute"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()
    
    // Push.
    app.tables["App Center"].staticTexts["Push"].tap()
    XCTAssertTrue(app.tables["Push"].switches["Set Enabled"].boolValue)
    app.buttons["App Center"].tap()
  }

  /**
   * There is a known bug with user defaults on iOS >= 10.
   */
  func testDisableSDKPersistance() {
    guard let `app` = app else {
      XCTFail()
      return
    }
    var appCenterButton = app.switches["Set Enabled"]
    XCTAssertTrue(appCenterButton.boolValue, "AppCenter doesn't enabled by default")
    
    // Disable SDK.
    appCenterButton.tap()
    XCTAssertFalse(appCenterButton.boolValue)
    
    // Several attempts for sure.
    for i in 0..<10 {
      
      // Restart application.
      sleep(1)
      XCUIDevice().press(.home)
      sleep(1)
      app.launch()
      
      appCenterButton = app.switches["Set Enabled"]
      XCTAssertFalse(appCenterButton.boolValue, "AppCenter doesn't disabled on next application run (\(i * 2 + 2) run)")
      
      // Enable SDK.
      appCenterButton.tap()
      
      XCTAssertTrue(appCenterButton.boolValue)
      
      // Restart application.
      sleep(1)
      XCUIDevice().press(XCUIDeviceButton.home)
      sleep(1)
      app.launch()
      
      appCenterButton = app.switches["Set Enabled"]
      XCTAssertTrue(appCenterButton.boolValue, "AppCenter doesn't enabled on next application run (\(i * 2 + 3) run)")
      
      // Disable SDK.
      appCenterButton.tap()
      
      XCTAssertFalse(appCenterButton.boolValue)
    }
  }

  func testCustomProperties() {
    guard let `app` = app else {
      return
    }
    
    // Go to custom properties page.
    app.tables["App Center"].staticTexts["Custom Properties"].tap()
    let customPropertiesTable = app.tables["Custom Properties"]
    
    // Add clear property.
    customPropertiesTable.staticTexts["Add Property"].tap()
    let clearPropertyCell = customPropertiesTable.cells.element(boundBy: 0)
    XCTAssertEqual("Clear", clearPropertyCell.textFields["Type"].value as! String)
    clearPropertyCell.textFields["Key"].clearAndTypeText("key0")
    
    // Add string property.
    customPropertiesTable.staticTexts["Add Property"].tap()
    let stringPropertyCell = customPropertiesTable.cells.element(boundBy: 1)
    stringPropertyCell.textFields["Type"].tap()
    app.pickerWheels.element.adjust(toPickerWheelValue: "String")
    app.toolbars.buttons["Done"].tap()
    XCTAssertEqual("String", stringPropertyCell.textFields["Type"].value as! String)
    stringPropertyCell.textFields["Key"].clearAndTypeText("key1")
    stringPropertyCell.textFields["Value"].clearAndTypeText("test1")
    
    // Add number property.
    customPropertiesTable.staticTexts["Add Property"].tap()
    let numbarPropertyCell = customPropertiesTable.cells.element(boundBy: 2)
    numbarPropertyCell.textFields["Type"].tap()
    app.pickerWheels.element.adjust(toPickerWheelValue: "Number")
    app.toolbars.buttons["Done"].tap()
    XCTAssertEqual("Number", numbarPropertyCell.textFields["Type"].value as! String)
    numbarPropertyCell.textFields["Key"].clearAndTypeText("key2")
    numbarPropertyCell.textFields["Value"].clearAndTypeText("-42.42")
    
    // Send properties.
    customPropertiesTable.buttons["Send Custom Properties"].tap()
    app.alerts.firstMatch.buttons["OK"].tap()
  }

  func testMiscellaneousInfo() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // Go to device info page.
    app.tables["App Center"].staticTexts["Device Info"].tap()

    // Check device info. Device info shouldn't contain an empty info.
    for cellIndex in 0..<app.cells.count {
      let cell : XCUIElement = app.cells.element(boundBy: cellIndex)
      let deviceInfo : String = cell.staticTexts.element(boundBy: 1).label
      XCTAssertNotNil(deviceInfo)
    }
    app.buttons["App Center"].tap()

    // Check install id.
    let installIdCell : XCUIElement = app.tables["App Center"].cell(containing: "Install ID")
    let installId : String = installIdCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(UUID(uuidString: installId))

    // Check app secret.
    let appSecretCell : XCUIElement = app.tables["App Center"].cell(containing: "App Secret")
    let appSecret : String = appSecretCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(UUID(uuidString: appSecret))

    // Check log url.
    let logUrlCell : XCUIElement = app.tables["App Center"].cell(containing: "Log URL")
    let logUrl : String = logUrlCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(URL(string: logUrl))
  }
}
