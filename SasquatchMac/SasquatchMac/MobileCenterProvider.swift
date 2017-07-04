
@objc class MobileCenterProvider:NSObject {

  var mobileCenter: MobileCenterDelegate?

  private static let instance = MobileCenterProvider()
  static func shared() -> MobileCenterProvider {
    return instance
  }
}
