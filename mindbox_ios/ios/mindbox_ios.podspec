#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mindbox_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mindbox_ios'
  s.version          = '2.13.4'
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
  s.dependency 'Mindbox', '2.13.4'
  s.dependency 'MindboxNotifications', '2.13.4'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end