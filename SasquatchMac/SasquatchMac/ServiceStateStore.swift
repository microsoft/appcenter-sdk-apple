import Foundation;

@objc class ServiceStateStore : NSObject {
  private static let AnalyticsKey : String = "MSAnalytics";
  private static let CrashesKey : String = "MSCrashes";

  class var AnalyticsState : Bool {
    get {
      return UserDefaults.standard.bool(forKey: AnalyticsKey);
    }
    set {
      UserDefaults.standard.set(newValue, forKey: AnalyticsKey);
      UserDefaults.standard.synchronize();
    }
  }

  class var CrashesState : Bool {
    get {
      return UserDefaults.standard.bool(forKey: CrashesKey);
    }
    set {
      UserDefaults.standard.set(newValue, forKey: CrashesKey);
      UserDefaults.standard.synchronize();
    }
  }
}
