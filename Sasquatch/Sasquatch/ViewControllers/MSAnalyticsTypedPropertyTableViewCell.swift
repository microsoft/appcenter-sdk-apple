import UIKit

@objc(MSAnalyticsTypedPropertyTableViewCell) class MSAnalyticsTypedPropertyTableViewCell: UITableViewCell {

  enum EventPropertyType : String {
    case String = "String"
    case Double = "Double"
    case Long = "Long"
    case Boolean = "Boolean"
    case DateTime = "DateTime"

    static let allValues = [String, Double, Long, Boolean, DateTime]
  }

  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var keyTextField: UITextField!
  @IBOutlet weak var typeTextField: UITextField!
  @IBOutlet weak var valueTextField: UITextField!
  @IBOutlet weak var boolValue: UISwitch!
  @IBOutlet var valueBottomConstraint: NSLayoutConstraint!
  private var typePickerView: MSEnumPicker<EventPropertyType>?
  private var datePickerView: MSDatePicker?

  public var type: EventPropertyType {
    get { return EventPropertyType(rawValue: typeTextField.text!)! }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.typePickerView = MSEnumPicker<EventPropertyType>(
      textField: self.typeTextField,
      allValues: EventPropertyType.allValues,
      onChange: {(index) in self.onChangeType(EventPropertyType.allValues[index])})
    self.typeTextField.delegate = self.typePickerView
    self.typeTextField.tintColor = UIColor.clear
    self.datePickerView = MSDatePicker(textField: self.valueTextField)
    prepareForReuse()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    self.keyTextField.text = ""
    self.typeTextField.text = EventPropertyType.String.rawValue
    self.onChangeType(EventPropertyType.String)
  }

  func onChangeType(_ type: EventPropertyType) {
    typeTextField.text = type.rawValue

    // Reset to default values.
    valueTextField.text = ""
    valueTextField.keyboardType = .default
    valueTextField.tintColor = keyTextField.tintColor
    valueTextField.delegate = nil
    valueTextField.inputView = nil
    valueTextField.inputAccessoryView = nil
    switch type {
    case .String:
      valueBottomConstraint.isActive = true
      valueLabel.isHidden = false
      valueTextField.isHidden = false
      valueTextField.keyboardType = .asciiCapable
      boolValue.isHidden = true
    case .Double, .Long:
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
  }

  func setPropertyTo(_ properties: MSEventProperties) {
    switch self.type {
    case .String:
      properties.setString(valueTextField.text!, forKey:keyTextField.text!)
      break
    case .Double:
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      let double = formatter.number(from: valueTextField.text ?? "")?.doubleValue ?? 0
      properties.setDouble(double, forKey:keyTextField.text!)
      break
    case .Long:
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      let long = formatter.number(from: valueTextField.text ?? "")?.int64Value ?? 0
      properties.setInt64(long, forKey:keyTextField.text!)
      break
    case .Boolean:
      properties.setBool(boolValue.isOn, forKey:keyTextField.text!)
      break
    case .DateTime:
      properties.setDate(datePickerView!.date!, forKey:keyTextField.text!)
      break
    }
  }
}
