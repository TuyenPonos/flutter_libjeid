#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_libjeid.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_libjeid'
  s.version          = '0.0.2'
  s.summary          = 'Flutter plugin to work with libjeid'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://ponos-tech.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ponos Tech' => 'info@ponos-tech.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.preserve_paths = 'libjeid.xcframework/**/*'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework libjeid' }
  s.vendored_frameworks = 'libjeid.xcframework'
end
