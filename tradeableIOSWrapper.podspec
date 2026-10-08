Pod::Spec.new do |s|
  s.name             = 'tradeableIOSWrapper'
  s.version          = '1.0.4'
  s.summary          = 'iOS Framework to embed Flutter trading widgets'
  s.description      = <<-DESC
  A native iOS framework that wraps the Tradeable Flutter SDK, allowing easy integration
  of Flutter-based trading widgets into native iOS apps with SwiftUI support.
                       DESC
  s.homepage         = 'https://github.com/deepakgrandhi/tradeableIOSWrapper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Deepak Grandhi' => 'deepakgrandhi@gmail.com' }
  s.source           = { :git => 'https://github.com/Tradeable/tradeableIOSWrapper.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  
  s.source_files = 'tradeableIOSWrapper/**/*.{h,m,swift}'
  s.public_header_files = 'tradeableIOSWrapper/**/*.h'
  
  # Flutter dependency - required for framework compilation
  s.dependency 'Flutter'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  
  s.user_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
