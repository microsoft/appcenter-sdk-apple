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
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    handleSystemAlert()


    // Enable SDK (we need it in case SDK was disabled by the test, which then failed and didn't enabled SDK back).
    let appCenterButton = app.tables["App Center"].switches["Set Enabled"]
    if (!appCenterButton.boolValue) {
      appCenterButton.tap()
    }
  }

  func testEnableDisableSDK() {
    guard let `app` = app else {
      XCTFail()
      return
    }
    let appCenterButton = app.tables["App Center"].switches["Set Enabled"]

    // SDK should be enabled.
    XCTAssertTrue(appCenterButton.boolValue)

    // Disable SDK.
    appCenterButton.tap()

    // All services should be disabled.
    // Push.
    XCTAssertFalse(app.tables["App Center"].switches["Push Enabled"].boolValue)
    
    // Analytics.
    app.tabBars.buttons["Analytics"].tap()
    XCTAssertFalse(app.tables["Analytics"].switches["Set Enabled"].boolValue)

    // Crashes.
    app.tabBars.buttons["Crashes"].tap()
    XCTAssertFalse(app.tables["Crashes"].switches["Set Enabled"].boolValue)

    // Distribute.
    app.tabBars.buttons["Distribution"].tap()
    XCTAssertFalse(app.tables["Distribution"].switches["Set Enabled"].boolValue)

    // Enable SDK.
    app.tabBars.buttons["App Center"].tap()
    appCenterButton.tap()

    // All services should be enabled.
    // Push.
    XCTAssertTrue(app.tables["App Center"].switches["Push Enabled"].boolValue)
    
    // Analytics.
    app.tabBars.buttons["Analytics"].tap()
    XCTAssertTrue(app.tables["Analytics"].switches["Set Enabled"].boolValue)

    // Crashes.
    app.tabBars.buttons["Crashes"].tap()
    XCTAssertTrue(app.tables["Crashes"].switches["Set Enabled"].boolValue)

    // Distribute.
    app.tabBars.buttons["Distribution"].tap()
    XCTAssertTrue(app.tables["Distribution"].switches["Set Enabled"].boolValue)
  }

  /**
   * There is a known bug with NSUserDefaults on iOS 10 and later.
   * See:
   *   https://forums.developer.apple.com/thread/61287
   *   http://www.openradar.me/radar?id=5057804138184704
   */
  func testDisableSDKPersistence() {
    guard let `app` = app else {
      XCTFail()
      return
    }
    var appCenterButton = app.tables["App Center"].switches["Set Enabled"]
    XCTAssertTrue(appCenterButton.boolValue, "AppCenter doesn't enabled by default")
    
    // Disable SDK.
    appCenterButton.tap()
    XCTAssertFalse(appCenterButton.boolValue)
    
    // Several attempts for sure.
    for i in 0..<3 {
      
      // Restart application.
      sleep(5)
      XCUIDevice().press(.home)
      sleep(5)
      app.launch()
      
      appCenterButton = app.tables["App Center"].switches["Set Enabled"]
      XCTAssertFalse(appCenterButton.boolValue, "AppCenter doesn't disabled on next application run (\(i * 2 + 2) run)")
      
      // Enable SDK.
      appCenterButton.tap()
      
      XCTAssertTrue(appCenterButton.boolValue)
      
      // Restart application.
      sleep(5)
      XCUIDevice().press(XCUIDeviceButton.home)
      sleep(5)
      app.launch()
      
      appCenterButton = app.tables["App Center"].switches["Set Enabled"]
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
    
    // Add string property.
    customPropertiesTable.staticTexts["Add Property"].tap()
    let stringPropertyCell = customPropertiesTable.cells.element(boundBy: 1)
    XCTAssertEqual("String", stringPropertyCell.textFields["Type"].value as! String)
    stringPropertyCell.textFields["Key"].clearAndTypeText("key0")
    stringPropertyCell.textFields["Value"].clearAndTypeText("test0")
    
    // Add clear property.
    customPropertiesTable.staticTexts["Add Property"].tap()
    let clearPropertyCell = customPropertiesTable.cells.element(boundBy: 1)
    stringPropertyCell.textFields["Type"].tap()
    app.pickerWheels.element.adjust(toPickerWheelValue: "Clear")
    app.toolbars.buttons["Done"].tap()
    XCTAssertEqual("Clear", clearPropertyCell.textFields["Type"].value as! String)
    clearPropertyCell.textFields["Key"].clearAndTypeText("key1")

    // Add number property.
    customPropertiesTable.staticTexts["Add Property"].tap()
    let numbarPropertyCell = customPropertiesTable.cells.element(boundBy: 1)
    numbarPropertyCell.textFields["Type"].tap()
    app.pickerWheels.element.adjust(toPickerWheelValue: "Number")
    app.toolbars.buttons["Done"].tap()
    XCTAssertEqual("Number", numbarPropertyCell.textFields["Type"].value as! String)
    numbarPropertyCell.textFields["Key"].clearAndTypeText("key2")
    numbarPropertyCell.textFields["Value"].clearAndTypeText("-42.42")
    
    // Send properties.
    customPropertiesTable.buttons["Send Custom Properties"].tap()
    app.alerts.element.buttons["OK"].tap()
  }

  func testMiscellaneousInfo() {
    guard let `app` = app else {
      XCTFail()
      return
    }

    // TODO: Uncomment when "Device Info" will be available. There is no UI now.
    /*
    // Go to device info page.
    app.tables["App Center"].staticTexts["Device Info"].tap()

    // Check device info. Device info shouldn't contain an empty info.
    for cellIndex in 0..<app.cells.count {
      let cell : XCUIElement = app.cells.element(boundBy: cellIndex)
      let deviceInfo : String = cell.staticTexts.element(boundBy: 1).label
      XCTAssertNotNil(deviceInfo)
    }
    app.buttons["App Center"].tap()
    */

    // Check install id.
    let installIdCell : XCUIElement = app.tables["App Center"].cell(containing: "Install ID")
    let installId : String = installIdCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(UUID(uuidString: installId))

    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    // Check app secret.
    let appSecretCell : XCUIElement = app.tables["App Center"].cell(containing: "App Secret")
    let appSecret : String = appSecretCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(UUID(uuidString: appSecret))
    #endif

    // Check log url.
    let logUrlCell : XCUIElement = app.tables["App Center"].cell(containing: "Log URL")
    let logUrl : String = logUrlCell.staticTexts.element(boundBy: 1).label
    XCTAssertNotNil(URL(string: logUrl))
  }
}
