/**
 * Protocol that all ViewControllers interacting with AppCenter should implement.
 */
protocol AppCenterProtocol : class {
  var appCenter : AppCenterDelegate! { get set }
}
