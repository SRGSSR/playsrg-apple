//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AppCenter
import AppCenterCrashes
import Firebase
import SRGAnalyticsIdentity
import SRGDataProviderCombine
import SRGUserData
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?
    
    private var cancellables = Set<AnyCancellable>()
#if DEBUG || NIGHTLY || BETA
    private var settingUpdatesCancellables = Set<AnyCancellable>()
#endif
    
    private func setupAppCenter() {
        guard let appCenterSecret = Bundle.main.object(forInfoDictionaryKey: "AppCenterSecret") as? String, !appCenterSecret.isEmpty else { return }
        AppCenter.start(withAppSecret: appCenterSecret, services: [Crashes.self])
    }
}
    
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        assert(NSClassFromString("ASIdentifierManager") == nil, "No implicit AdSupport.framework dependency must be found")
        
        PlayApplicationRunOnce({ completionHandler in
            PlayFirebaseConfiguration.clearCache()
            completionHandler(true)
        }, "FirebaseConfigurationReset")
        
        PlayApplicationRunOnce({ completionHandler in
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: PlaySRGSettingServiceIdentifier)
            userDefaults.synchronize()
            completionHandler(true)
        }, "DataProviderServiceURLChange")
        
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        
        #if !DEBUG
        setupAppCenter()
        #endif
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        let configuration = ApplicationConfiguration.shared
        application.accessibilityLanguage = configuration.voiceOverLanguageCode
        
        if let identityWebserviceURL = configuration.identityWebserviceURL,
           let identityWebsiteURL = configuration.identityWebsiteURL {
            SRGIdentityService.current = SRGIdentityService(webserviceURL: identityWebserviceURL, websiteURL: identityWebsiteURL)
            
            NotificationCenter.default.weakPublisher(for: .SRGIdentityServiceUserDidCancelLogin, object: SRGIdentityService.current)
                .sink { _ in
                    AnalyticsEvent.identity(action: .cancelLogin).send()
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.weakPublisher(for: .SRGIdentityServiceUserDidLogin, object: SRGIdentityService.current)
                .sink { _ in
                    AnalyticsEvent.identity(action: .login).send()
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.weakPublisher(for: .SRGIdentityServiceUserDidLogout, object: SRGIdentityService.current)
                .sink { notification in
                    let unexpectedLogout = notification.userInfo?[SRGIdentityServiceUnauthorizedKey] as? Bool ?? false

                    let action = unexpectedLogout ? .unexpectedLogout : .logout as AnalyticsIdentityAction
                    AnalyticsEvent.identity(action: action).send()
                }
                .store(in: &cancellables)
        }
        
        let cachesDirectoryUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
        let storeFileUrl = cachesDirectoryUrl.appendingPathComponent("PlayData.sqlite")
        SRGUserData.current = SRGUserData(storeFileURL: storeFileUrl, serviceURL: configuration.userDataServiceURL, identityService: SRGIdentityService.current)
        
        UserConsentHelper.setup()
        
        let analyticsConfiguration = SRGAnalyticsConfiguration(
            businessUnitIdentifier: configuration.analyticsBusinessUnitIdentifier,
            sourceKey: configuration.analyticsSourceKey,
            siteName: configuration.siteName
        )
        SRGAnalyticsTracker.shared.start(with: analyticsConfiguration, dataSource: self, identityService: SRGIdentityService.current)
        
#if DEBUG || NIGHTLY || BETA
        Publishers.Merge(
            ApplicationSignal.settingUpdates(at: \.PlaySRGSettingServiceIdentifier),
            ApplicationSignal.settingUpdates(at: \.PlaySRGSettingUserLocation)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateDataProvider()
        }
        .store(in: &settingUpdatesCancellables)
#endif
        setupDataProvider()
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
    
    private func setupDataProvider() {
        let dataProvider = SRGDataProvider(serviceURL: ApplicationSettingServiceURL())
#if DEBUG || NIGHTLY || BETA
        dataProvider.globalParameters = ApplicationSettingGlobalParameters()
#endif
        SRGDataProvider.current = dataProvider
    }
    
    private func updateDataProvider() {
        URLCache.shared.removeAllCachedResponses()
        
        setupDataProvider()
        
        // Stop the current player (Picture in picture included)
        // TODO: For perfectly safe behavior when the service URL is changed, we should have all Letterbox
        //       view controllers observe URL settings change and do the following in such cases. This is probably
        //       overkill for the time being.
    }
}

extension AppDelegate: SRGAnalyticsTrackerDataSource {
    var srg_globalLabels: SRGAnalyticsLabels {
        SRGAnalyticsLabels.play_globalLabels
    }
}
