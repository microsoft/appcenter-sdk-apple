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
}
