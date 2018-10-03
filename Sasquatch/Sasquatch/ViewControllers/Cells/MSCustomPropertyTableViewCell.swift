import UIKit

@objc(MSCustomPropertyTableViewCell) class MSCustomPropertyTableViewCell: UITableViewCell {
  
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
  private var typePickerView: MSEnumPicker<CustomPropertyType>?
  private var datePickerView: MSDatePicker?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.typePickerView = MSEnumPicker<CustomPropertyType>(
      textField: self.typeTextField,
      allValues: CustomPropertyType.allValues,
      onChange: {(index) in self.onChangeType(CustomPropertyType.allValues[index])})
    self.typeTextField.delegate = self.typePickerView
    self.typeTextField.tintColor = UIColor.clear
    self.datePickerView = MSDatePicker(textField: self.valueTextField)
    prepareForReuse()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    self.keyTextField.text = ""
    self.typeTextField.text = CustomPropertyType.Clear.rawValue
    self.onChangeType(CustomPropertyType.Clear)
  }

  func onChangeType(_ type: CustomPropertyType) {
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
      valueTextField.delegate = self.datePickerView
      boolValue.isHidden = true
      self.datePickerView?.showDatePicker()
    }
    
    // Apply constraints.
    contentView.layoutIfNeeded()
    
    // Animate table.
    let tableView: UITableView? = self.tableView()
    tableView?.beginUpdates()
    tableView?.endUpdates()
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
