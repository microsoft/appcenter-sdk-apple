import Foundation;

@objc class ServiceStateStore : NSObject {
  private static let AnalyticsKey : String = "kMSAnalyticsIsEnabledKey";
  private static let CrashesKey : String = "kMSCrashesIsEnabledKey";

  class var AnalyticsState : Bool {
    get {
      return UserDefaults.standard.bool(forKey: AnalyticsKey);
    }
  }

  class var CrashesState : Bool {
    get {
      return UserDefaults.standard.bool(forKey: CrashesKey);
    }
  }
}
