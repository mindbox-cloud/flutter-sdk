#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mindbox_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mindbox_ios'
  s.version          = '1.0.0'
  s.summary          = 'Mindbox Flutter SDK'
  s.description      = <<-DESC
The implementation of 'mindbox' plugin for the iOS platform
                       DESC
  s.homepage         = 'https://mindbox.cloud/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mindbox' => 'it@mindbox.ru' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Mindbox', '~> 1.3.0'
  s.dependency 'MindboxNotifications', '~> 1.3.0'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
