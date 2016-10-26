Pod::Spec.new do |s|
  s.name              = 'Sonoma'
  s.version           = '0.1.3'

  s.summary           = 'Sonoma for iOS.'
  s.description       = <<-DESC
                       This is Sonoma for iOS. We are awesome.

                        DESC

  s.homepage          = 'http://sonoma.hockeyapp.com/'
  #s.documentation_url = "http://hockeyapp.net/help/sdk/ios/#{s.version}/"

  s.license           = { :type => 'MIT',  :file => 'SonomaSDK-iOS-0.1.3/LICENSE'}
  s.author            = { 'Microsoft' => 'support@hockeyapp.net' }

  s.platform          = :ios, '8.0'  
  s.source = { :http => "https://s3.amazonaws.com/hockey-app-download/sonoma/ios/SonomaSDK-iOS-0.1.3.zip" }
  s.preserve_path = 'SonomaSDK-iOS-0.1.3/LICENSE'

  s.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'

  s.default_subspec   = 'SonomaCore'

  s.subspec 'SonomaCore' do |ss|
      ss.frameworks = 'Foundation',  'SystemConfiguration', 'UIKit'
      ss.vendored_frameworks = 'SonomaSDK-iOS-0.1.3/SonomaCore.framework'
  end

 s.subspec 'SonomaAnalytics' do |ss|
      ss.frameworks = 'Foundation',  'UIKit'
      ss.dependency 'Sonoma/SonomaCore'
      ss.vendored_frameworks = 'SonomaSDK-iOS-0.1.3/SonomaAnalytics.framework'
  end

  s.subspec 'SonomaCrash' do |ss|
      ss.frameworks = 'Foundation'
      ss.libraries = 'z', 'c++'
      ss.dependency 'Sonoma/SonomaCore'
      ss.vendored_frameworks = 'SonomaSDK-iOS-0.1.3/SonomaAnalytics.framework'
  end


end