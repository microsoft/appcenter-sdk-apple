import XCTest

extension XCUIElement {
  
  /**
   * Return bool value. Useful for switches.
   */
  var boolValue : Bool {
    get {
      return self.value as! String == "1"
    }
  }
  
  /**
   * Filter cells by label.
   */
  private func filterCells(containing labels: [String]) -> XCUIElementQuery {
    var cells = self.cells
    for label in labels {
      cells = cells.containing(NSPredicate(format: "label CONTAINS %@", label))
    }
    return cells
  }
  
  /**
   * Find cell with label contains the string.
   */
  func cell(containing labels: String...) -> XCUIElement {
    return filterCells(containing: labels).element
  }
  
  /**
   * Clear any current text in the field before typing in the new value.
   */
  func clearAndTypeText(_ text: String) {
    self.tap()
    if let stringValue = self.value as? String {
      self.typeText(stringValue.characters.map { _ in XCUIKeyboardKeyDelete }.joined(separator: ""))
    }
    self.typeText(text)
  }
}

extension XCTestCase {
  
  /**
   * Deal with system alerts.
   */
  func handleSystemAlert() {
    
    // Note: addUIInterruptionMonitor doesn't work.
    // See https://forums.developer.apple.com/thread/86989
    
    // Use springboard.
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alert = springboard.alerts.element
    
    // There is some alert.
    if (alert.exists) {
      
      // In case if this is some permission dialog, allow it.
      let allow = alert.buttons["Allow"]
      if (allow.exists) {
        allow.tap()
        return
      }
      
      // "OK" button for allow in iOS 9.
      let ok = alert.buttons["OK"]
      if (ok.exists) {
        ok.tap()
        return
      }
    }
  }
}
