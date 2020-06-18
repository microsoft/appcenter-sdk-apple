Pod::Spec.new do |s|
  s.name              = 'AppCenter'
  s.version           = '3.3.0'

  s.summary           = 'Visual Studio App Center is your continuous integration, delivery and learning solution for iOS and macOS apps.'
  s.description       = <<-DESC
                      Visual Studio App Center is your continuous integration, delivery and learning solution for iOS and macOS apps.
                      Get faster release cycles, higher-quality apps, and the insights to build what users want.

                      The App Center SDK uses a modular architecture so you can use any or all of the following services:

                      1. App Center Analytics (iOS, macOS and tvOS):
                      App Center Analytics helps you understand user behavior and customer engagement to improve your app. The SDK automatically captures session count, device properties like model, OS version, etc. You can define your own custom events to measure things that matter to you. All the information captured is available in the App Center portal for you to analyze the data.

                      2. App Center Crashes (iOS, macOS and tvOS):
                      App Center Crashes will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be sent to App Center. Collecting crashes works for both beta and live apps, i.e. those submitted to the App Store. Crash logs contain valuable information for you to help fix the crash.

                      3. App Center Distribute (iOS only):
                      App Center Distribute lets your users install a new version of the app when you distribute it with App Center. With a new version of the app available, the SDK will present an update dialog to the users to either download or postpone the new version. Once they choose to update, the SDK will start to update your application. This feature is automatically disabled on versions of your app deployed to the Apple App Store.

                      4. App Center Push (iOS and macOS):
                      App Center Push enables you to send push notifications to users of your app from the App Center portal. You can also segment your user base based on a set of properties and send them targeted notifications. Not available for tvOS SDK.

                        DESC

  s.homepage          = 'https://appcenter.ms'
  s.documentation_url = "https://docs.microsoft.com/en-us/appcenter/sdk"
  s.social_media_url = 'https://twitter.com/vsappcenter'

  s.license           = { :type => 'MIT', :file => 'AppCenter-SDK-Apple/LICENSE' }
  s.author            = { 'Microsoft' => 'appcentersdk@microsoft.com' }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '11.0'
  s.source = { :http => "https://github.com/microsoft/appcenter-sdk-apple/releases/download/#{s.version}/AppCenter-SDK-Apple-#{s.version}.zip" }

  s.preserve_path = 'AppCenter-SDK-Apple/README.md'

  s.default_subspecs = 'Analytics', 'Crashes'

  s.subspec 'Core' do |ss|
    ss.frameworks = 'Foundation', 'SystemConfiguration'
    ss.ios.frameworks = 'CoreTelephony', 'UIKit'
    ss.osx.frameworks = 'AppKit'
    ss.tvos.frameworks = 'UIKit'
    ss.ios.vendored_frameworks = "AppCenter-SDK-Apple/iOS/AppCenter.framework"
    ss.osx.vendored_frameworks = "AppCenter-SDK-Apple/macOS/AppCenter.framework"
    ss.tvos.vendored_frameworks = "AppCenter-SDK-Apple/tvOS/AppCenter.framework"
    ss.libraries = 'z', 'sqlite3'
  end

 s.subspec 'Analytics' do |ss|
    ss.dependency 'AppCenter/Core'
    ss.frameworks = 'Foundation'
    ss.ios.frameworks = 'UIKit'
    ss.osx.frameworks = 'AppKit'
    ss.tvos.frameworks = 'UIKit'
    ss.ios.vendored_frameworks = "AppCenter-SDK-Apple/iOS/AppCenterAnalytics.framework"
    ss.osx.vendored_frameworks = "AppCenter-SDK-Apple/macOS/AppCenterAnalytics.framework"
    ss.tvos.vendored_frameworks = "AppCenter-SDK-Apple/tvOS/AppCenterAnalytics.framework"
  end

  s.subspec 'Crashes' do |ss|
    ss.dependency 'AppCenter/Core'
    ss.frameworks = 'Foundation'
    ss.libraries = 'z', 'c++'
    ss.ios.vendored_frameworks = "AppCenter-SDK-Apple/iOS/AppCenterCrashes.framework"
    ss.osx.vendored_frameworks = "AppCenter-SDK-Apple/macOS/AppCenterCrashes.framework"
    ss.tvos.vendored_frameworks = "AppCenter-SDK-Apple/tvOS/AppCenterCrashes.framework"
  end

 s.subspec 'Distribute' do |ss|
    ss.dependency 'AppCenter/Core'
    ss.frameworks = 'Foundation'
    ss.ios.frameworks = 'UIKit'
    ss.ios.weak_frameworks = 'SafariServices'
    ss.ios.resource_bundle = { 'AppCenterDistributeResources' => ['AppCenter-SDK-Apple/iOS/AppCenterDistributeResources.bundle/*.lproj'] }
    ss.ios.vendored_frameworks = "AppCenter-SDK-Apple/iOS/AppCenterDistribute.framework"
 end

 s.subspec 'Push' do |ss|
    ss.dependency 'AppCenter/Core'
    ss.frameworks = 'Foundation'
    ss.ios.frameworks = 'UIKit'
    ss.osx.frameworks = 'AppKit'
    ss.ios.weak_frameworks = 'UserNotifications'
    ss.ios.vendored_frameworks = "AppCenter-SDK-Apple/iOS/AppCenterPush.framework"
    ss.osx.vendored_frameworks = "AppCenter-SDK-Apple/macOS/AppCenterPush.framework"
 end

end
