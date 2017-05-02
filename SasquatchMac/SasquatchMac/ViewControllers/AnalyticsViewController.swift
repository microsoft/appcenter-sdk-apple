import Cocoa
import MobileCenterMac
import MobileCenterAnalyticsMac

// FIXME: trackPage has been hidden in MSAnalytics temporarily. Use internal until the feature comes back.
class AnalyticsViewController : NSViewController {

  @IBOutlet var setEnabledButton : NSButton?;

  override func viewDidLoad() {
    super.viewDidLoad()
    setEnabledButton?.state = MSAnalytics.isEnabled() ? 1 : 0
  }

  @IBAction func trackEvent(_ : AnyObject) {
    MSAnalytics.trackEvent("myEvent");
  }

  @IBAction func trackEventWithProperties(_ : AnyObject) {
    MSAnalytics.trackEvent("myEvent", withProperties: ["gender":"male", "age":"20", "title":"SDE"]);
  }

  @IBAction func trackPage(_ : AnyObject) {
    NSLog("trackPage");
  }

  @IBAction func trackPageWithProperties(_ : AnyObject) {
    NSLog("trackPageWithProperties");
  }

  @IBAction func setEnabled(sender : NSButton) {
    MSAnalytics.setEnabled(sender.state == 1)
    sender.state = MSAnalytics.isEnabled() ? 1 : 0
  }
}
