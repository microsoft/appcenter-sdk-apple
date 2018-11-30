import UIKit

class MSAnalyticsResultViewController: UITableViewController {

  var analyticsResult: MSAnalyticsResult? = nil
  
  // Statistics
  @IBOutlet weak var sendingCountLabel: UILabel!
  @IBOutlet weak var succeededCountLabel: UILabel!
  @IBOutlet weak var failedCountLabel: UILabel!
  
  // Last event
  @IBOutlet weak var eventNameLabel: UILabel!
  @IBOutlet weak var eventIdentifierLabel: UILabel!
  @IBOutlet weak var eventPropertiesCountLabel: UILabel!
  @IBOutlet weak var eventStatusLabel: UILabel!

  @IBAction func onDismissButtonPress(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateLabels()
    NotificationCenter.default.addObserver(self, selector: #selector(updateAnalyticsResult), name: .updateAnalyticsResult, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func updateAnalyticsResult(_ notification: Notification) {
    DispatchQueue.main.async {
      self.updateLabels()
      self.reloadCells()
    }
  }

  func updateLabels() {
    guard let analyticsResult = self.analyticsResult else {
      return
    }
    self.sendingCountLabel.text = "\(analyticsResult.sendingEvents.count)"
    self.succeededCountLabel.text = "\(analyticsResult.succeededEvents.count)"
    self.failedCountLabel.text = "\(analyticsResult.failedEvents.count)"
    
    self.eventNameLabel.text = analyticsResult.lastEvent?.name ?? " "
    self.eventIdentifierLabel.text = analyticsResult.lastEvent?.eventId ?? " "
    #if ACTIVE_COMPILATION_CONDITION_PUPPET
    self.eventPropertiesCountLabel.text = "\(analyticsResult.lastEvent?.typedProperties?.properties.count ?? 0)"
    #else
    self.eventPropertiesCountLabel.text = "0"
    #endif
    self.eventStatusLabel.text = analyticsResult.lastEventState ?? " "
  }
  
  func reloadCells() {
    var rows = [IndexPath]()
    let rowsInSection = Int(tableView.numberOfRows(inSection: 0))
    for row in 0..<rowsInSection {
      rows.append(IndexPath(row: row, section: 0))
    }
    tableView.reloadRows(at: rows, with: .none)
  }
}

