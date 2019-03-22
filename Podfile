source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:SRGSSR/srgpodspecs-ios.git'

platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

abstract_target 'PlaySRG' do
  pod 'AutoCoding', '~> 2.2.3'
  pod 'BDKCollectionIndexView', '~> 2.0.0'
  pod 'Firebase/RemoteConfig', '~> 5.15.0'
  pod 'google-cast-sdk', '~> 4.3.4' 
  pod 'PPBadgeView', '~> 2.1.0'
  
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

  project 'PlaySRG.xcodeproj', 'Debug' => :debug, 'Nightly' => :release, 'Beta' => :release, 'AppStore' => :release
end
