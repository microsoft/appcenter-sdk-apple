/**
 * Protocol that all ViewControllers interacting with AppCenter should implement.
 */
@objc protocol AppCenterProtocol : class {
  var appCenter : AppCenterDelegate! { get set }
}
