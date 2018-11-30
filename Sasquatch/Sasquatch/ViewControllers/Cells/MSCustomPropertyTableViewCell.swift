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

  public var key: String {
    get { return self.keyTextField.text! }
    set(key) { self.keyTextField.text = key }
  }

  public var type: CustomPropertyType {
    get { return CustomPropertyType(rawValue: typeTextField.text!)! }
    set(type) { self.onChangeType(type) }
  }

  public var value: Any? {
    get {
      switch type {
      case .Clear:
        return nil
      case .String:
        return valueTextField.text!
      case .Number:
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: valueTextField.text ?? "") ?? 0
      case .Boolean:
        return boolValue.isOn
      case .DateTime:
        return datePickerView!.date!
      }
    }
    set(value) {
      switch type {
      case .Clear:
        break
      case .String, .Number:
        valueTextField.text = value as? String
      case .Boolean:
        boolValue.isOn = value as! Bool
      case .DateTime:
        datePickerView!.date = value as? Date
      }
    }
  }

  public var state: (key: String, type: CustomPropertyType, value: Any?) {
    get { return (key, type, value) }
    set(state) {
      key = state.key
      type = state.type
      value = state.value
    }
  }

  public var onChange: (((key: String, type: CustomPropertyType, value: Any?)) -> Void)?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.typePickerView = MSEnumPicker<CustomPropertyType>(
      textField: self.typeTextField,
      allValues: CustomPropertyType.allValues,
      onChange: { index in
        self.type = CustomPropertyType.allValues[index]
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
    state = ("", CustomPropertyType.String, "")
  }

  @IBAction func dismissKeyboard(_ sender: UITextField!) {
    sender.resignFirstResponder()
  }

  @IBAction func onChangeKey() {
    self.onChange?(self.state)
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

  @IBAction func onChangeValue() {
    self.onChange?(self.state)
  }

  func tableView() -> UITableView? {
    var view = superview
    while view != nil && (view is UITableView) == false {
      view = view?.superview
    }
    return view as? UITableView
  }
}
