# frozen_string_literal: true

source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

def ios_pods
  pod 'AutoCoding'
end

def tvos_pods
  pod 'TvOSTextViewer'
end

abstract_target 'Play SRG' do
  abstract_target 'iOS' do
    platform :ios, '14.1'

    target 'Play SRF' do
      ios_pods
    end

    target 'Play RSI' do
      ios_pods
    end

    target 'Play RTS' do
      ios_pods
    end

    target 'Play RTR' do
      ios_pods
    end

    target 'Play SWI' do
      ios_pods
    end

    project 'PlaySRG.xcodeproj',
            'Debug' => :debug,
            'Nightly' => :release,
            'Nightly_AppCenter' => :release,
            'Beta' => :release,
            'Beta_AppCenter' => :release,
            'AppStore' => :release
  end

  abstract_target 'tvOS' do
    platform :tvos, '14.0'

    target 'Play SRF TV' do
      tvos_pods
    end

    target 'Play RSI TV' do
      tvos_pods
    end

    target 'Play RTS TV' do
      tvos_pods
    end

    target 'Play RTR TV' do
      tvos_pods
    end

    target 'Play SWI TV' do
      tvos_pods
    end

    project 'PlaySRG.xcodeproj',
            'Debug' => :debug,
            'Nightly' => :release,
            'Nightly_AppCenter' => :release,
            'Beta' => :release,
            'Beta_AppCenter' => :release,
            'AppStore' => :release
  end
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        config.build_settings.delete 'TVOS_DEPLOYMENT_TARGET'
      end
    end
  end
end
