import XCTest

extension XCUIElement {
  var boolValue : Bool {
    get {
      return self.value as! String == "1"
    }
  }
  
  private func filterCells(containing labels: [String]) -> XCUIElementQuery {
    var cells = self.cells
    for label in labels {
      cells = cells.containing(NSPredicate(format: "label CONTAINS %@", label))
    }
    return cells
  }
  
  func cell(containing labels: String...) -> XCUIElement {
    return filterCells(containing: labels).element
  }
  
  /**
   * Clear any current text in the field before typing in the new value.
   */
  func clearAndTypeText(_ text: String) {
    guard let stringValue = self.value as? String else {
      XCTFail("Tried to clear and type text into a non string value")
      return
    }
    self.tap()
    self.typeText(stringValue.characters.map { _ in XCUIKeyboardKeyDelete }.joined(separator: ""))
    self.typeText(text)
  }
}
