/**
 * Protocol that all ViewControllers interacting with App Center should implement.
 */
protocol AppCenterProtocol: class {
  var appCenter: AppCenterDelegate! { get set }
}
