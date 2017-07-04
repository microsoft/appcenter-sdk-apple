import Cocoa

// FIXME: trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
class AnalyticsViewController : NSViewController {

  var mobileCenter: MobileCenterDelegate?
  
  @IBOutlet var setEnabledButton : NSButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    mobileCenter = MobileCenterProvider.shared().mobileCenter
    setEnabledButton?.state = mobileCenter!.isAnalyticsEnabled() ? 1 : 0
  }

  @IBAction func trackEvent(_ : AnyObject) {
    if let mobileCenter = mobileCenter {
      mobileCenter.trackEvent("myEvent")
    }
  }

  @IBAction func trackEventWithProperties(_ : AnyObject) {
    if let mobileCenter = mobileCenter {
      mobileCenter.trackEvent("myEvent", withProperties: ["gender":"male", "age":"20", "title":"SDE"]);
    }
  }

  @IBAction func trackPage(_ : AnyObject) {
    NSLog("trackPage");
  }

  @IBAction func trackPageWithProperties(_ : AnyObject) {
    NSLog("trackPageWithProperties");
  }

  @IBAction func setEnabled(sender : NSButton) {
    mobileCenter?.setAnalyticsEnabled(sender.state == 1)
    sender.state = mobileCenter!.isAnalyticsEnabled() ? 1 : 0
  }
}
