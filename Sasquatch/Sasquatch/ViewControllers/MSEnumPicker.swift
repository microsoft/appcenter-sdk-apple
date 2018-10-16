import UIKit

class MSEnumPicker<E: RawRepresentable & Equatable> : NSObject, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate where E.RawValue == String {
  
  private let textField: UITextField!
  private let allValues: [E]
  private let onChange: (Int) -> Void
  
  init(textField: UITextField!, allValues: [E], onChange: @escaping (Int) -> Void) {
    self.textField = textField
    self.allValues = allValues
    self.onChange = onChange
    super.init()
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    showEnumPicker()
    return true
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return false
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return self.allValues.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return self.allValues[row].rawValue
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    self.textField.text = self.allValues[row].rawValue
    self.onChange(row)
  }
  
  func showEnumPicker() {
    let startupModePickerView = UIPickerView()
    startupModePickerView.backgroundColor = UIColor.white
    startupModePickerView.showsSelectionIndicator = true
    startupModePickerView.dataSource = self
    startupModePickerView.delegate = self
    let value = E(rawValue: self.textField.text!)!
    startupModePickerView.selectRow(self.allValues.index(of: value)!, inComponent: 0, animated: false)
    
    let toolbar: UIToolbar? = toolBarForPicker()
    self.textField.inputView = startupModePickerView
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
}
