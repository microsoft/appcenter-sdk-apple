Pod::Spec.new do |s|
  s.name              = 'MobileCenter'
  s.version           = '0.1.4'

  s.summary           = 'Mobile Center SDK for iOS.'
  s.description       = <<-DESC
                       This is the Mobile Center SDK for iOS.

                        DESC

  s.homepage          = 'http://sonoma.hockeyapp.com/'
  #s.documentation_url = "http://hockeyapp.net/help/sdk/ios/#{s.version}/"

  s.license           = { :type => 'MIT',  :file => 'SonomaSDK-iOS-0.1.4/LICENSE'}
  s.author            = { 'Microsoft' => 'support@hockeyapp.net' }

  s.platform          = :ios, '8.0'  
  s.source = { :http => "https://s3.amazonaws.com/hockey-app-download/sonoma/ios/SonomaSDK-iOS-0.1.4.zip" }
  s.preserve_path = 'MobileCenter-SDK-iOS/LICENSE'

  s.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'

  s.default_subspecs = 'Analytics', 'Crashes'

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