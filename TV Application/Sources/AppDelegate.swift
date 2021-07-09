//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AppCenter
import AppCenterCrashes
import Firebase
import SRGAnalyticsIdentity
import SRGAppearanceSwift
import SRGDataProviderCombine
import SRGUserData
import SwiftUI
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private var cancellables = Set<AnyCancellable>()
    
    private static func configuredTabBarController(tabBarController: UITabBarController) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .srgGray2
        appearance.selectionIndicatorTintColor = .hexadecimal("#979797")
        
        let itemAppearance = appearance.inlineLayoutAppearance
        itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: SRGFont.font(family: .text, weight: .medium, size: 28) as UIFont,
                                                     NSAttributedString.Key.foregroundColor: UIColor.white]
        itemAppearance.normal.iconColor = .white
        
        let activeColor = UIColor.hexadecimal("#161616")!
        let activeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: activeColor]
        itemAppearance.selected.titleTextAttributes = activeTitleTextAttributes
        itemAppearance.selected.iconColor = activeColor
        itemAppearance.focused.titleTextAttributes = activeTitleTextAttributes
        itemAppearance.focused.iconColor = activeColor
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.view.backgroundColor = .srgGray1
    }
    
    private func applicationRootViewController() -> UIViewController {
        var viewControllers = [UIViewController]()
        
        let videosViewController = PageViewController(id: .video)
        videosViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Home", comment: "Home tab title"), image: nil, tag: 0)
        videosViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.videosTabBarItem.rawValue
        viewControllers.append(videosViewController)
        
        let configuration = ApplicationConfiguration.shared
        
        #if DEBUG
        if let firstChannel = configuration.radioChannels.first {
            let audiosViewController = PageViewController(id: .audio(channel: firstChannel))
            audiosViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Audios", comment: "Audios tab title"), image: nil, tag: 1)
            audiosViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.audiosTabBarItem.rawValue
            viewControllers.append(audiosViewController)
        }
        #endif
        
        if !configuration.liveHomeSections.isEmpty {
            let liveViewController = PageViewController(id: .live)
            liveViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), image: nil, tag: 2)
            liveViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.livestreamsTabBarItem.rawValue
            viewControllers.append(liveViewController)
        }
        
        if !configuration.areShowsUnavailable {
            let showsViewController = SectionViewController(section: .configured(ConfiguredSection(type: .tvAllShows, contentPresentationType: .swimlane)))
            showsViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Shows", comment: "Shows tab title"), image: nil, tag: 3)
            showsViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.showsTabBarItem.rawValue
            viewControllers.append(showsViewController)
        }
        
        let searchViewController = SearchViewController()
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 4)
        searchViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.searchTabBarItem.rawValue
        viewControllers.append(searchViewController)
        
        let profileViewController = UIHostingController(rootView: ProfileView())
        profileViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "profile_tab")!.withRenderingMode(.alwaysTemplate), tag: 7)
        profileViewController.tabBarItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Profile", "Profile button label on home view")
        profileViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.profileTabBarItem.rawValue
        viewControllers.append(profileViewController)
        
        if viewControllers.count > 1 {
            let tabBarController = UITabBarController()
            Self.configuredTabBarController(tabBarController: tabBarController)
            tabBarController.viewControllers = viewControllers
            return tabBarController
        }
        else {
            return viewControllers.first!
        }
    }
    
    private func setupAppCenter() {
        guard let appCenterSecret = Bundle.main.object(forInfoDictionaryKey: "AppCenterSecret") as? String, !appCenterSecret.isEmpty else { return }
        AppCenter.start(withAppSecret: appCenterSecret, services: [Crashes.self])
    }
    
    // MARK: - UIApplicationDelegate protocol
    
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
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.makeKeyAndVisible()
        window!.rootViewController = applicationRootViewController()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            Self.configuredTabBarController(tabBarController: tabBarController)
        }
    }
    
    // See URL_SCHEMES.md
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let deeplinkAction = url.host else { return false }
        
        if deeplinkAction == "media" {
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
        else if deeplinkAction == "show" {
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
