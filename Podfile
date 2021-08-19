# frozen_string_literal: true

source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

abstract_target 'Play SRG' do
  abstract_target 'iOS' do
    platform :ios, '12.0'

    pod 'AutoCoding'
    pod 'BDKCollectionIndexView'
    pod 'FSCalendar'
    pod 'google-cast-sdk-no-bluetooth'
    pod 'InAppSettingsKit', '3.3.0'
    pod 'MaterialComponents/Tabs', '118.2.0'   # Tabs replaced with new implementation as of 119.0.0

    target 'Play SRF' do
    end

    target 'Play RSI' do
    end

    target 'Play RTS' do
    end

    target 'Play RTR' do
    end

    target 'Play SWI' do
    end

    project 'PlaySRG.xcodeproj',
            'Debug' => :debug,
            'Nightly' => :release,
            'Beta' => :release,
            'AppStore' => :release
  end

  abstract_target 'tvOS' do
    platform :tvos, '14.0'

    pod 'TvOSTextViewer'

    target 'Play SRF TV' do
    end

    target 'Play RSI TV' do
    end

    target 'Play RTS TV' do
    end

    target 'Play RTR TV' do
    end

    target 'Play SWI TV' do
    end

    project 'PlaySRG.xcodeproj',
            'Debug' => :debug,
            'Nightly' => :release,
            'Beta' => :release,
            'AppStore' => :release
  end
end

# Fix deployment target warnings. See https://stackoverflow.com/questions/37160688/set-deployment-target-for-cocoapodss-pod
# Since all pods are not compatible with arm64 iOS simulator architecture
post_install do |lib|
  lib.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
