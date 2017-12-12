@objc class AppCenterProvider:NSObject {

  var appCenter: AppCenterDelegate?

  private static let instance = AppCenterProvider()
  static func shared() -> AppCenterProvider {
    return instance
  }
}
