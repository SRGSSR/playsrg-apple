# frozen_string_literal: true

source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

abstract_target 'Play SRG' do
  pod 'Firebase/Analytics', '~> 6.30.0'
  pod 'Firebase/RemoteConfig', '~> 6.30.0'

  abstract_target 'iOS' do
    platform :ios, '12.0'

    pod 'AutoCoding', '~> 2.2.3'
    pod 'BDKCollectionIndexView', '~> 2.0.0'
    pod 'FSCalendar', '2.7.9'
    pod 'google-cast-sdk-no-bluetooth', '~> 4.4.6'
    pod 'InAppSettingsKit', '~> 3.0.1'
    pod 'MaterialComponents/Tabs', '~> 109.5'
    pod 'MGSwipeTableCell', '~> 1.6.8'
    pod 'paper-onboarding', '~> 6.1.5'
    pod 'SwiftMessages', '~> 7.0.1'

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
post_install do |lib|
  lib.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
