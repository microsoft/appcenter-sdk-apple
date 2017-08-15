Pod::Spec.new do |s|
  s.name              = 'MobileCenter'
  s.version           = '0.11.2'

  s.summary           = 'Mobile Center is mission control for mobile apps. Get faster release cycles, higher-quality apps, and the insights to build what users want.'
  s.description       = <<-DESC
                      Mobile Center is mission control for mobile apps.
                      Get faster release cycles, higher-quality apps, and the insights to build what users want.

                      The Mobile Center SDK uses a modular architecture so you can use any or all of the following services: 

                      1. Mobile Center Analytics (iOS, macOS and tvOS):
                      Mobile Center Analytics helps you understand user behavior and customer engagement to improve your app. The SDK automatically captures session count, device properties like model, OS version, etc. You can define your own custom events to measure things that matter to you. All the information captured is available in the Mobile Center portal for you to analyze the data.

                      2. Mobile Center Crashes (iOS, macOS and tvOS):
                      Mobile Center Distribute will let your users install a new version of the app when you distribute it via the Mobile Center. With a new version of the app available, the SDK will present an update dialog to the users to either download or postpone the new version. Once they choose to update, the SDK will start to update your application. This feature will NOT work if your app is deployed to the app store.

                      3. Mobile Center Distribute (iOS only):
                      Mobile Center Distribute provides the capability to display in-app updates to your app users when a new version of the application is released. Not available for macOS and tvOS SDKs.

                      4. Mobile Center Push (iOS and macOS):
                      Mobile Center Push enables you to send push notifications to users of your app from the Mobile Center portal. You can also segment your user base based on a set of properties and send them targeted notifications. Not available for tvOS SDK.

                        DESC

  s.homepage          = 'https://mobile.azure.com'
  s.documentation_url = "https://docs.mobile.azure.com/sdk/ios/"

  s.license           = { :type => 'MIT',  :file => 'MobileCenter-SDK-Apple/LICENSE'}
  s.author            = { 'Microsoft' => 'mobilecentersdk@microsoft.com' }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source = { :http => "https://github.com/microsoft/mobile-center-sdk-ios/releases/download/#{s.version}/MobileCenter-SDK-Apple-#{s.version}.zip" }
  s.preserve_path = "MobileCenter-SDK-Apple/LICENSE"

  s.default_subspecs = 'Analytics', 'Crashes'

  s.subspec 'Core' do |ss|
    ss.frameworks = 'Foundation', 'SystemConfiguration'
    ss.ios.frameworks = 'CoreTelephony', 'UIKit'
    ss.osx.frameworks = 'AppKit'
    ss.tvos.frameworks = 'UIKit'
    ss.ios.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenter.framework"
    ss.osx.vendored_frameworks = "MobileCenter-SDK-Apple/macOS/MobileCenter.framework"
    ss.tvos.vendored_frameworks = "MobileCenter-SDK-Apple/tvOS/MobileCenter.framework"
    ss.libraries = 'sqlite3'
  end

 s.subspec 'Analytics' do |ss|
    ss.frameworks = 'Foundation'
    ss.dependency 'MobileCenter/Core'
    ss.ios.frameworks = 'UIKit'
    ss.osx.frameworks = 'AppKit'
    ss.tvos.frameworks = 'UIKit'
    ss.ios.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterAnalytics.framework"
    ss.osx.vendored_frameworks = "MobileCenter-SDK-Apple/macOS/MobileCenterAnalytics.framework"
    ss.tvos.vendored_frameworks = "MobileCenter-SDK-Apple/tvOS/MobileCenterAnalytics.framework"
  end

  s.subspec 'Crashes' do |ss|
    ss.frameworks = 'Foundation'
    ss.libraries = 'z', 'c++'
    ss.dependency 'MobileCenter/Core'
    ss.ios.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterCrashes.framework"
    ss.osx.vendored_frameworks = "MobileCenter-SDK-Apple/macOS/MobileCenterCrashes.framework"
    ss.tvos.vendored_frameworks = "MobileCenter-SDK-Apple/tvOS/MobileCenterCrashes.framework"
  end

 s.subspec 'Distribute' do |ss|
    ss.frameworks = 'Foundation', 'UIKit'
    ss.weak_frameworks = 'SafariServices'
    ss.dependency 'MobileCenter/Core'
    ss.ios.resource_bundle = { 'MobileCenterDistributeResources' => ['MobileCenter-SDK-Apple/iOS/MobileCenterDistributeResources.bundle/*.lproj'] }
    ss.ios.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterDistribute.framework"
 end

 s.subspec 'Push' do |ss|
    ss.frameworks = 'Foundation'
    ss.ios.frameworks = 'UIKit'
    ss.osx.frameworks = 'AppKit'
    ss.ios.weak_frameworks = 'UserNotifications'
    ss.dependency 'MobileCenter/Core'
    ss.ios.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterPush.framework"
    ss.osx.vendored_frameworks = "MobileCenter-SDK-Apple/macOS/MobileCenterPush.framework"
 end

end
