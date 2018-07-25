import UIKit

class MSAnalyticsResultViewController: UITableViewController {

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
    NotificationCenter.default.addObserver(self, selector: #selector(updateAnalyticsResult),
                                           name: NSNotification.Name.updateAnalyticsResult, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func updateAnalyticsResult(_ notification: Notification) {
    DispatchQueue.main.async {
      let analyticsResult = notification.object as! MSAnalyticsResult
      self.updateLabels(analyticsResult)
      self.reloadCells()
    }
  }

  func updateLabels(_ analyticsResult: MSAnalyticsResult!) {
    self.sendingCountLabel.text = "\(analyticsResult.sendingEvents.count)"
    self.succeededCountLabel.text = "\(analyticsResult.succeededEvents.count)"
    self.failedCountLabel.text = "\(analyticsResult.sendingEvents.count)"
    
    self.eventNameLabel.text = "\(analyticsResult.lastEvent?.name ?? " ")"
    self.eventIdentifierLabel.text = "\(analyticsResult.lastEvent?.eventId ?? " ")"
    self.eventPropertiesCountLabel.text = "\(analyticsResult.lastEvent?.properties?.count ?? 0)"
    //self.eventStatusLabel.text = "\(analyticsResult.sendingEvents.count)"
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

