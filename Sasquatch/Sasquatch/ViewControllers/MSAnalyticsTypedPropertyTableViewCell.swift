import UIKit

@objc(MSAnalyticsTypedPropertyTableViewCell) class MSAnalyticsTypedPropertyTableViewCell: UITableViewCell {
  typealias PropertyState = (key: String, type: EventPropertyType, value: Any)

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

  public var key: String {
    get { return self.keyTextField.text! }
    set(key) { self.keyTextField.text = key }
  }

  public var type: EventPropertyType {
    get { return EventPropertyType(rawValue: typeTextField.text!)! }
    set(type) { self.onChangeType(type) }
  }

  public var value: Any {
    get {
      switch type {
      case .String:
        return valueTextField.text!
      case .Double:
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: valueTextField.text ?? "")?.doubleValue ?? Double(0)
      case .Long:
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: valueTextField.text ?? "")?.int64Value ?? Int64(0)
      case .Boolean:
        return boolValue.isOn
      case .DateTime:
        return datePickerView!.date!
      }
    }
    set(value) {
      switch type {
      case .String, .Double, .Long:
        valueTextField.text = "\(value)"
      case .Boolean:
        boolValue.isOn = value as! Bool
      case .DateTime:
        datePickerView!.date = value as? Date
      }
    }
  }

  public var state: PropertyState {
    get { return (key, type, value) }
    set(state) {
      key = state.key
      type = state.type
      value = state.value
    }
  }

  public var onChange: ((PropertyState) -> Void)?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.typePickerView = MSEnumPicker<EventPropertyType>(
      textField: self.typeTextField,
      allValues: EventPropertyType.allValues,
      onChange: { index in
        self.type = EventPropertyType.allValues[index]
        self.onChange?(self.state)
      }
    )
    self.typeTextField.delegate = self.typePickerView
    self.typeTextField.tintColor = UIColor.clear
    self.datePickerView = MSDatePicker(textField: self.valueTextField)
    prepareForReuse()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    state = ("", EventPropertyType.String, "")
  }

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }

  @IBAction func onChangeKey() {
    self.onChange?(self.state)
  }

  func onChangeType(_ type: EventPropertyType) {
    typeTextField.text = type.rawValue

    // Reset to default values.
    valueTextField.keyboardType = .default
    valueTextField.tintColor = keyTextField.tintColor
    valueTextField.delegate = nil
    valueTextField.inputView = nil
    valueTextField.inputAccessoryView = nil
    switch type {
    case .String:
      valueTextField.text = ""
      valueBottomConstraint.isActive = true
      valueLabel.isHidden = false
      valueTextField.isHidden = false
      valueTextField.keyboardType = .asciiCapable
      boolValue.isHidden = true
    case .Double, .Long:
      valueTextField.text = "0"
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

  @IBAction func onChangeValue() {
    self.onChange?(self.state)
  }
}
