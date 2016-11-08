Pod::Spec.new do |s|
  s.name              = 'MobileCenter'
  s.version           = '0.2.0'

  s.summary           = 'Mobile Center SDK for iOS.'
  s.description       = <<-DESC
                     The Mobile Center SDK lets you add Mobile Center services to your iOS application.

                    The SDK is currently in private beta release and supports the following services:

Analytics: Mobile Center Analytics helps you understand user behavior and customer engagement to improve your iOS app. The SDK automatically captures session count, device properties like model, OS version etc. and pages. You can define your own custom events to measure things that matter to your business. All the information captured is available in the Mobile Center portal for you to analyze the data.

Crashes: The Mobile Center SDK will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be forwarded to Mobile Center. Collecting crashes works for both beta and live apps, i.e. those submitted to App Store. Crash logs contain viable information for you to help resolve the issue. Crashes uses PLCrashReporter 1.3.

                        DESC

  s.homepage          = 'http://sonoma.hockeyapp.com/'
  #s.documentation_url = "http://hockeyapp.net/help/sdk/ios/#{s.version}/"

  s.license           = { :type => 'MIT',  :file => 'MobileCenter-SDK-iOS-0.2.0/LICENSE'}
  s.author            = { 'Microsoft' => 'mobilecentersdk@microsoft.com' }

  s.platform          = :ios, '8.0'  
  s.source = { :http => "https://s3.amazonaws.com/hockey-app-download/sonoma/ios/SonomaSDK-iOS-0.2.0.zip" }
  s.preserve_path = 'MobileCenter-SDK-iOS/LICENSE'

  s.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'

  s.default_subspecs = 'MobileCenterAnalytics', 'MobileCenterCrashes'

  s.subspec 'MobileCenter' do |ss|
      ss.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'
      ss.vendored_frameworks = 'MobileCenter-SDK-iOS/MobileCenter.framework'
  end

 s.subspec 'MobileCenterAnalytics' do |ss|
      ss.frameworks = 'CoreTelephony', Foundation',  'UIKit'
      ss.dependency 'MobileCenter/MobileCenter'
      ss.vendored_frameworks = 'MobileCenter-SDK-iOS/MobileCenterAnalytics.framework'
  end

  s.subspec 'MobileCenterCrashes' do |ss|
      ss.frameworks = 'Foundation', 'UIKit'
      ss.libraries = 'z', 'c++'
      ss.dependency 'MobileCenter/MobileCenter'
      ss.vendored_frameworks = 'MobileCenter-SDK-iOS/MobileCenterCrashes.framework'
  end


end