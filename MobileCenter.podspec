Pod::Spec.new do |s|
  s.name              = 'MobileCenter'
  s.version           = '0.15.0'

  s.summary           = 'Mobile Center is mission control for mobile apps. Get faster release cycles, higher-quality apps, and the insights to build what users want.'
  s.description       = <<-DESC
                      Mobile Center is mission control for mobile apps.
                      Get faster release cycles, higher-quality apps, and the insights to build what users want.

                      The Mobile Center SDK uses a modular architecture so you can use any or all of the following services: 

                      1. Mobile Center Analytics:
                      Mobile Center Analytics helps you understand user behavior and customer engagement to improve your app. The SDK automatically captures session count, device properties like model, OS version, etc. You can define your own custom events to measure things that matter to you. All the information captured is available in the Mobile Center portal for you to analyze the data.

                      2. Mobile Center Crashes:
                      Mobile Center Crashes will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be sent to Mobile Center. Collecting crashes works for both beta and live apps, i.e. those submitted to the App Store. Crash logs contain valuable information for you to help fix the crash.

                      3. Mobile Center Distribute:
                      Mobile Center Distribute will let your users install a new version of the app when you distribute it via the Mobile Center. With a new version of the app available, the SDK will present an update dialog to the users to either download or postpone the new version. Once they choose to update, the SDK will start to update your application. This feature will NOT work if your app is deployed to the app store.

                      4. Mobile Center Push:
                      Mobile Center Push enables you to send push notifications to users of your app from the Mobile Center portal. You can also segment your user base based on a set of properties and send them targeted notifications.

                        DESC

  s.homepage          = 'https://mobile.azure.com'
  s.documentation_url = "https://docs.mobile.azure.com/sdk/ios/"

  s.license           = { :type => 'MIT',  :file => 'MobileCenter-SDK-Apple/LICENSE'}
  s.author            = { 'Microsoft' => 'mobilecentersdk@microsoft.com' }

  s.platform          = :ios, '8.0'
  s.source = { :http => "https://github.com/microsoft/mobile-center-sdk-ios/releases/download/#{s.version}/MobileCenter-SDK-Apple-#{s.version}.zip" }

  s.deprecated = true

  s.preserve_path = "MobileCenter-SDK-Apple/LICENSE"

  s.default_subspecs = 'Analytics', 'Crashes'

  s.subspec 'Core' do |ss|
    ss.frameworks = 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'UIKit'
    ss.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenter.framework"
    ss.libraries = 'sqlite3'
  end

 s.subspec 'Analytics' do |ss|
    ss.frameworks = 'Foundation', 'UIKit'
    ss.dependency 'MobileCenter/Core'
    ss.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterAnalytics.framework"
  end

  s.subspec 'Crashes' do |ss|
    ss.frameworks = 'Foundation'
    ss.libraries = 'z', 'c++'
    ss.dependency 'MobileCenter/Core'
    ss.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterCrashes.framework"
  end

 s.subspec 'Distribute' do |ss|
    ss.frameworks = 'Foundation', 'UIKit'
    ss.weak_frameworks = 'SafariServices'
    ss.dependency 'MobileCenter/Core'
    ss.resource_bundle = { 'MobileCenterDistributeResources' => ['MobileCenter-SDK-Apple/iOS/MobileCenterDistributeResources.bundle/*.lproj'] }
    ss.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterDistribute.framework"
 end

 s.subspec 'Push' do |ss|
    ss.frameworks = 'Foundation', 'UIKit'
    ss.weak_frameworks = 'UserNotifications'
    ss.dependency 'MobileCenter/Core'
    ss.vendored_frameworks = "MobileCenter-SDK-Apple/iOS/MobileCenterPush.framework"
 end

end
