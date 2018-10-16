import UIKit

class MSDatePicker: NSObject, UITextFieldDelegate {

  private let textField: UITextField!
  private var datePickerView: UIDatePicker?

  var date: Date? {
    get { return datePickerView?.date }
    set(date) { datePickerView?.date = date ?? Date() }
  }

  init(textField: UITextField!) {
    self.textField = textField
    super.init()
  }

  func showDatePicker() {
    datePickerView = UIDatePicker()
    datePickerView?.backgroundColor = UIColor.white
    datePickerView?.datePickerMode = .dateAndTime
    datePickerView?.date = Date()

    // Update label.
    datePickerView?.addTarget(self, action: #selector(self.datePickerChanged), for: .valueChanged)
    datePickerChanged()
    let toolbar: UIToolbar? = toolBarForPicker()
    self.textField.inputView = datePickerView
    self.textField.inputAccessoryView = toolbar
  }

  func toolBarForPicker() -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneClicked))
    toolbar.items = [flexibleSpace, doneButton]
    return toolbar
  }

  func doneClicked() {
    self.textField.resignFirstResponder()
  }

  func datePickerChanged() {
    var dateFormatter: DateFormatter? = nil
    if dateFormatter == nil {
      dateFormatter = DateFormatter()
      dateFormatter?.dateStyle = .long
      dateFormatter?.timeStyle = .medium
    }
    self.textField.text = dateFormatter?.string(from: self.date!)
  }
}
