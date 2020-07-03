// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSEnumPicker<E: RawRepresentable & Equatable> : NSObject, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate where E.RawValue == String {
  
  private let textField: UITextField!
  private let allValues: [E]
  private let onChange: (Int) -> Void
  
  // In some cases, we may want to override the controller that
  // shows alert for mac catalyst (when the controller is not the root one).
  // Example: MSCustomPropertiesViewController.
  private var viewController: UIViewController?
  
  init(textField: UITextField!, allValues: [E], onChange: @escaping (Int) -> Void) {
    self.textField = textField
    self.allValues = allValues
    self.onChange = onChange
    super.init()
  }
  
  public func overrideViewController(with viewController: UIViewController?) {
    self.viewController = viewController
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
#if !targetEnvironment(macCatalyst)
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
    let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .alert)
    let pickedValue = E(rawValue: self.textField.text!)!
    for value in self.allValues {
      
      // Red style for picked option.
      let style: UIAlertAction.Style = value.rawValue == pickedValue.rawValue ? .destructive : .default
      let action = UIAlertAction(title: value.rawValue, style: style, handler: {
        (_ action : UIAlertAction) -> Void in
        self.textField.text! = action.title!
        let pickedValue = self.allValues.first { value -> Bool in
          return value.rawValue == action.title!
        }
        let index = self.allValues.index(of: pickedValue!)
        self.onChange(index!)
      })
      optionMenu.addAction(action)
    }
    optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    let rootViewController: UIViewController? = self.viewController ?? UIApplication.shared.windows.first?.rootViewController
    rootViewController?.present(optionMenu, animated: true, completion: nil)
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
