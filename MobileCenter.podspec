Pod::Spec.new do |s|
  s.name              = 'MobileCenter'
  s.version           = '0.3.1'

  s.summary           = 'Add Mobile Center SDK to your app to collect crash reports & understand user behavior by analyzing the session, user or device information.'
  s.description       = <<-DESC
                     Add Mobile Center services to your app and collect crash reports and understand user behavior by analyzing the session, user and device information for your app. The SDK is currently in public preview and supports the following services:

                      1. Analytics:
                      Mobile Center Analytics helps you understand user behavior and customer engagement to improve your iOS app. The SDK automatically captures session count, device properties like model, OS version etc. and pages. You can define your own custom events to measure things that matter to your business. All the information captured is available in the Mobile Center portal for you to analyze the data.

                      2. Crashes: 
                      The Mobile Center SDK will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be forwarded to Mobile Center. Collecting crashes works for both beta and live apps, i.e. those submitted to App Store. Crash logs contain viable information for you to help resolve the issue. Crashes uses PLCrashReporter 1.3.
                        DESC

  s.homepage          = 'https://mobile.azure.com'
  #s.documentation_url = "https://docs.mobile.azure.com/sdk/ios/"

  s.license           = { :type => 'MIT',  :file => 'MobileCenter-SDK-iOS/LICENSE'}
  s.author            = { 'Microsoft' => 'mobilecentersdk@microsoft.com' }

  s.platform          = :ios, '8.0'  
  s.source = { :http => "https://mobilecentersdkdev.blob.core.windows.net/sdk/MobileCenter-SDK-iOS-#{s.version}.zip" }



  s.preserve_path = "MobileCenter-SDK-iOS/LICENSE"

  s.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'

  s.default_subspecs = 'MobileCenterAnalytics', 'MobileCenterCrashes'

  s.subspec 'MobileCenter' do |ss|
      ss.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'
      ss.vendored_frameworks = "MobileCenter-SDK-iOS/MobileCenter.framework"
  end

 s.subspec 'MobileCenterAnalytics' do |ss|
      ss.frameworks = 'CoreTelephony', 'Foundation', 'UIKit'
      ss.dependency 'MobileCenter/MobileCenter'
      ss.vendored_frameworks = "MobileCenter-SDK-iOS/MobileCenterAnalytics.framework"
  end

  s.subspec 'MobileCenterCrashes' do |ss|
      ss.frameworks = 'Foundation', 'UIKit'
      ss.libraries = 'z', 'c++'
      ss.dependency 'MobileCenter/MobileCenter'
      ss.vendored_frameworks = "MobileCenter-SDK-iOS/MobileCenterCrashes.framework"
  end


end