/**
 * Protocol that all ViewControllers interacting with MobileCenter should implement.
 */
protocol MobileCenterProtocol: class {
  var mobileCenter: MobileCenterDelegate? { get set }
}
