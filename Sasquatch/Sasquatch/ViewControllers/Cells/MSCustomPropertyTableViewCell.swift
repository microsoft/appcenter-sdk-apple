import UIKit

@objc(MSCustomPropertyTableViewCell) class MSCustomPropertyTableViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
  
  enum CustomPropertyType : String {
    case Clear = "Clear"
    case String = "String"
    case Number = "Number"
    case Boolean = "Boolean"
    case DateTime = "DateTime"
    
    static let allValues = [Clear, String, Number, Boolean, DateTime]
  }
  
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var keyTextField: UITextField!
  @IBOutlet weak var typeTextField: UITextField!
  @IBOutlet weak var valueTextField: UITextField!
  @IBOutlet weak var boolValue: UISwitch!
  @IBOutlet var valueBottomConstraint: NSLayoutConstraint!
  var typePickerView: UIPickerView?
  var datePickerView: UIDatePicker?

  override func awakeFromNib() {
    super.awakeFromNib()
    typeTextField.delegate = self
    prepareForReuse()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    keyTextField.text = ""
    typeTextField.text = CustomPropertyType.Clear.rawValue
    typeTextField.tintColor = UIColor.clear
    pickerView(typePickerView ?? UIPickerView(), didSelectRow: 0, inComponent: 0)
  }
  
  func showTypePicker() {
    typePickerView = UIPickerView()
    typePickerView?.backgroundColor = UIColor.white
    typePickerView?.showsSelectionIndicator = true
    typePickerView?.dataSource = self
    typePickerView?.delegate = self
    
    // Select current type.
    let type = CustomPropertyType(rawValue: typeTextField.text!)!
    typePickerView?.selectRow(CustomPropertyType.allValues.index(of: type)!, inComponent: 0, animated: false)
    
    let toolbar: UIToolbar? = toolBarForPicker()
    typeTextField.inputView = typePickerView
    typeTextField.inputAccessoryView = toolbar
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
    valueTextField.inputView = datePickerView
    valueTextField.inputAccessoryView = toolbar
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if textField == typeTextField {
      showTypePicker()
      return true
    } else if textField == valueTextField {
      return true
    }
    return false
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
    typeTextField.resignFirstResponder()
    valueTextField.resignFirstResponder()
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return false
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return CustomPropertyType.allValues.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return CustomPropertyType.allValues[row].rawValue
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let type = CustomPropertyType.allValues[row]
    typeTextField.text = type.rawValue
    
    // Reset to default values.
    valueTextField.text = ""
    valueTextField.keyboardType = .default
    valueTextField.tintColor = keyTextField.tintColor
    valueTextField.delegate = nil
    valueTextField.inputView = nil
    valueTextField.inputAccessoryView = nil
    switch type {
    case .Clear:
      valueBottomConstraint.isActive = false
      valueLabel.isHidden = true
      valueTextField.isHidden = true
      boolValue.isHidden = true
    case .String:
      valueBottomConstraint.isActive = true
      valueLabel.isHidden = false
      valueTextField.isHidden = false
      valueTextField.keyboardType = .asciiCapable
      boolValue.isHidden = true
    case .Number:
      valueBottomConstraint.isActive = true
      valueLabel.isHidden = false
      valueTextField.isHidden = false
      valueTextField.keyboardType = .numbersAndPunctuation
      boolValue.isHidden = true
    case .Boolean:
      valueBottomConstraint.isActive = true
      valueLabel.isHidden = false
      valueTextField.isHidden = true
      boolValue.isHidden = false
    case .DateTime:
      valueBottomConstraint.isActive = true
      valueLabel.isHidden = false
      valueTextField.isHidden = false
      valueTextField.tintColor = UIColor.clear
      valueTextField.delegate = self
      boolValue.isHidden = true
      showDatePicker()
    }
    
    // Apply constraints.
    contentView.layoutIfNeeded()
    
    // Animate table.
    let tableView: UITableView? = self.tableView()
    tableView?.beginUpdates()
    tableView?.endUpdates()
  }
  
  func datePickerChanged() {
    var dateFormatter: DateFormatter? = nil
    if dateFormatter == nil {
      dateFormatter = DateFormatter()
      dateFormatter?.dateStyle = .long
      dateFormatter?.timeStyle = .medium
    }
    valueTextField.text = dateFormatter?.string(from: (datePickerView?.date)!)
  }

  func tableView() -> UITableView? {
    var view = superview
    while view != nil && (view is UITableView) == false {
      view = view?.superview
    }
    return view as? UITableView
  }
  
  func setPropertyTo(_ properties: MSCustomProperties) {
    let type = CustomPropertyType(rawValue: typeTextField.text!)!
    switch type {
    case .Clear:
      properties.clearProperty(forKey: keyTextField.text)
    case .String:
      properties.setString(valueTextField.text, forKey: keyTextField.text)
    case .Number:
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      properties.setNumber(formatter.number(from: valueTextField.text ?? ""), forKey: keyTextField.text)
    case .Boolean:
      properties.setBool(boolValue.isOn, forKey: keyTextField.text)
    case .DateTime:
      properties.setDate(datePickerView?.date, forKey: keyTextField.text)
    }
  }
}
