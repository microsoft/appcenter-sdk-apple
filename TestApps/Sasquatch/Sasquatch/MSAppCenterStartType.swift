/**
 * Enumeration for different types of start of AppCenter.
 */

@objc enum MSAppCenterStartType: Int{
  case AppSecret = 1, TenantId, Both

  func name() -> String {
    switch self {
      case .AppSecret: return "App secret"
      case .TenantId: return "Tenant id"
      case .Both: return "Both"
    }
  }

  static let allValues = [AppSecret, TenantId, Both]
}
