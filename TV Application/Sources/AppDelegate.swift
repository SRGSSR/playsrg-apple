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
    
    private func setupAppCenter() {
        guard let appCenterSecret = Bundle.main.object(forInfoDictionaryKey: "AppCenterSecret") as? String, !appCenterSecret.isEmpty else { return }
        AppCenter.start(withAppSecret: appCenterSecret, services: [Crashes.self])
    }
}
    
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        assert(NSClassFromString("ASIdentifierManager") == nil, "No implicit AdSupport.framework dependency must be found")
        
        // Processes run once in the lifetime of the application
        PlayApplicationRunOnce({ completionHandler -> Void in
            PlayFirebaseConfiguration.clearCache()
            completionHandler(true)
        }, "FirebaseConfigurationReset", nil)
        
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
            
            NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidCancelLogin, object: SRGIdentityService.current)
                .sink { _ in
                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = AnalyticsSource.button.rawValue
                    labels.type = AnalyticsType.actionCancelLogin.rawValue
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.identity.rawValue, labels: labels)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidLogin, object: SRGIdentityService.current)
                .sink { _ in
                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = AnalyticsSource.button.rawValue
                    labels.type = AnalyticsType.actionLogin.rawValue
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.identity.rawValue, labels: labels)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: .SRGIdentityServiceUserDidLogout, object: SRGIdentityService.current)
                .sink { notification in
                    let unexpectedLogout = notification.userInfo?[SRGIdentityServiceUnauthorizedKey] as? Bool ?? false

                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = unexpectedLogout ? AnalyticsSource.automatic.rawValue : AnalyticsSource.button.rawValue
                    labels.type = AnalyticsType.actionLogout.rawValue
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.identity.rawValue, labels: labels)
                }
                .store(in: &cancellables)
        }
        
        let cachesDirectoryUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
        let storeFileUrl = cachesDirectoryUrl.appendingPathComponent("PlayData.sqlite")
        SRGUserData.current = SRGUserData(storeFileURL: storeFileUrl, serviceURL: configuration.userDataServiceURL, identityService: SRGIdentityService.current)
        
        let analyticsConfiguration = SRGAnalyticsConfiguration(businessUnitIdentifier: configuration.analyticsBusinessUnitIdentifier,
                                                               container: configuration.analyticsContainer,
                                                               siteName: configuration.tvSiteName)
        #if DEBUG || NIGHTLY || BETA
        analyticsConfiguration.environmentMode = .preProduction
        #endif
        SRGAnalyticsTracker.shared.start(with: analyticsConfiguration, identityService: SRGIdentityService.current)
        
        SRGDataProvider.current = SRGDataProvider(serviceURL: SRGIntegrationLayerProductionServiceURL())
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
    
    // See URL_SCHEMES.md
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let deeplLinkAction = url.host else { return false }
        
        if deeplLinkAction == "media" {
            let mediaUrn = url.lastPathComponent
            SRGDataProvider.current?.media(withUrn: mediaUrn)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                } receiveValue: { media in
                    navigateToMedia(media)
                }
                .store(in: &cancellables)
            return true
        }
        else if deeplLinkAction == "show" {
            let showUrn = url.lastPathComponent
            SRGDataProvider.current?.show(withUrn: showUrn)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                } receiveValue: { show in
                    navigateToShow(show)
                }
                .store(in: &cancellables)
            return true
        }
        return false
    }
}
