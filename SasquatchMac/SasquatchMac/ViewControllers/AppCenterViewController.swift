import Cocoa
import CoreLocation

class AppCenterViewController : NSViewController, CLLocationManagerDelegate {

  var appCenter: AppCenterDelegate = AppCenterProvider.shared().appCenter!    

  @IBOutlet var installIdLabel : NSTextField?
  @IBOutlet var appSecretLabel : NSTextField?
  @IBOutlet var logURLLabel : NSTextField?
  @IBOutlet var userIdLabel : NSTextField?
  @IBOutlet var setEnabledButton : NSButton?
  @IBOutlet weak var overrideCountryCodeButton: NSButton!

  private var locationManager: CLLocationManager = CLLocationManager()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    installIdLabel?.stringValue = appCenter.installId()
    appSecretLabel?.stringValue = appCenter.appSecret()
    logURLLabel?.stringValue = appCenter.logUrl()
    userIdLabel?.stringValue = UserDefaults.standard.string(forKey: "userId") ?? ""
    setEnabledButton?.state = appCenter.isAppCenterEnabled() ? 1 : 0
    
    self.locationManager.delegate = self
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    self.locationManager.stopUpdatingLocation()
    let userLocation:CLLocation = locations[0] as CLLocation
    CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
      if error == nil {
        self.appCenter.setCountryCode(placemarks?.first?.isoCountryCode)
      }
    }
  }
  
  func locationManager(_ Manager: CLLocationManager, didFailWithError error: Error){
    print("Failed to find user's location: \(error.localizedDescription)")
  }

  @IBAction func setEnabled(sender : NSButton) {
    appCenter.setAppCenterEnabled(sender.state == 1)
    sender.state = appCenter.isAppCenterEnabled() ? 1 : 0
  }

  @IBAction func userIdChanged(sender: NSTextField) {
    let text = sender.stringValue
    let userId = !text.isEmpty ? text : nil
    UserDefaults.standard.set(userId, forKey: "userId")
    appCenter.setUserId(userId)
  }
  
  @IBAction func overrideCountryCode(_ sender: NSButton) {
    if CLLocationManager.locationServicesEnabled() {
      self.locationManager.startUpdatingLocation()
    }
  }
}
