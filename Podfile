source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

workspace 'YouMovie.xcworkspace'
project 'YouMovie.xcodeproj'

# For All Targets
def all_targets
  pod 'ObjectMapper', '~> 4.2'
end

# Project Pods
def project_pods
    pod 'Alamofire', '~> 5.9'
    pod 'BetterSegmentedControl', '~> 1.3'
    pod 'Kingfisher', '~> 7.12'
end

# Test Pods
def test_pods
  pod 'Quick', '~> 7.0'
  pod 'Nimble', '~> 13.0'
  pod 'OHHTTPStubs/Swift', '~> 9.1'
end

# YouMovie Target
target 'YouMovie' do
  all_targets
  project_pods      
end

# YouMovieTests Target
target 'YouMovieTests' do
  all_targets
  test_pods
end

# inhibit_all_warnings!
post_install do |installer|
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'

          # Fix for Xcode 14+ code signing
          config.build_settings['CODE_SIGN_IDENTITY'] = ''
      end
  end
end
