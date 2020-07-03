// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSEnumPicker<E: RawRepresentable & Equatable> : NSObject, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate where E.RawValue == String {
  
  private let textField: UITextField!
  private let allValues: [E]
  private let onChange: (Int) -> Void
  private let viewController: UIViewController?
  
  init(textField: UITextField!, viewController: UIViewController? = nil, allValues: [E], onChange: @escaping (Int) -> Void) {
    self.textField = textField
    self.allValues = allValues
    self.onChange = onChange
    self.viewController = viewController
    super.init()
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    #if TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
    showEnumPicker()
    #else
    showActionSheetPicker()
    #endif
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
  
  func showActionSheetPicker() {
    let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
    let pickedValue = E(rawValue: self.textField.text!)!
    let action = UIAlertAction(title: pickedValue.rawValue, style: .destructive)
    optionMenu.addAction(action)
    for value in self.allValues {
      if (value.rawValue == pickedValue.rawValue) {
        continue
      }
      let action = UIAlertAction(title: value.rawValue, style: .default)
      optionMenu.addAction(action)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    optionMenu.addAction(cancelAction)
    self.viewController?.present(optionMenu, animated: true, completion: nil)
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
  
  @objc func doneClicked() {
    self.textField.resignFirstResponder()
  }
}
