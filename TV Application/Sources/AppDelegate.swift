//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AppCenter
import AppCenterCrashes
import Firebase
import SRGAnalyticsIdentity
import SRGAppearance
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
        appearance.backgroundColor = .play_cardGrayBackground
        appearance.selectionIndicatorTintColor = .srg_color(fromHexadecimalString: "#979797")
        
        let itemAppearance = appearance.inlineLayoutAppearance
        itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.font: UIFont.srg_mediumFont(withSize: 28),
                                                     NSAttributedString.Key.foregroundColor: UIColor.white]
        itemAppearance.normal.iconColor = .white
        
        let activeColor = UIColor.srg_color(fromHexadecimalString: "#161616")!
        let activeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: activeColor]
        itemAppearance.selected.titleTextAttributes = activeTitleTextAttributes
        itemAppearance.selected.iconColor = activeColor
        itemAppearance.focused.titleTextAttributes = activeTitleTextAttributes
        itemAppearance.focused.iconColor = activeColor
        
        tabBarController.tabBar.standardAppearance = appearance
    }
    
    private func applicationRootViewController() -> UIViewController? {
        var viewControllers = [UIViewController]()
        
        let videosViewController = UIHostingController(rootView: VideosView())
        videosViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Home", comment: "Home tab title"), image: nil, tag: 0)
        viewControllers.append(videosViewController)
        
        let configuration = ApplicationConfiguration.shared
        
        #if DEBUG
        if !configuration.radioChannels.isEmpty {
            let audiosViewController = UIHostingController(rootView: AudiosView())
            audiosViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Audios", comment: "Audios tab title"), image: nil, tag: 1)
            viewControllers.append(audiosViewController)
        }
        #endif
        
        if !configuration.liveHomeSections.isEmpty {
            let liveViewController = UIHostingController(rootView: LiveView())
            liveViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), image: nil, tag: 2)
            viewControllers.append(liveViewController)
        }
        
        if configuration.videoHomeSections.contains(NSNumber(value: HomeSection.tvShowsAccess.rawValue)) {
            let showsViewController = UIHostingController(rootView: ShowsView())
            showsViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Shows", comment: "Shows tab title"), image: nil, tag: 3)
            viewControllers.append(showsViewController)
        }
        
        let searchViewController = SearchViewController()
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 4)
        viewControllers.append(searchViewController)
        
        #if DEBUG
        let historyViewController = UIHostingController(rootView: HistoryView())
        historyViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("History", comment: "History tab title"), image: nil, tag: 6)
        viewControllers.append(historyViewController)
        #endif
        
        #if DEBUG || NIGHTLY
        let profileViewController = UIHostingController(rootView: ProfileView())
        profileViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "profile-34")!.withRenderingMode(.alwaysTemplate), tag: 7)
        profileViewController.tabBarItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Profile", "Profile button label on home view")
        viewControllers.append(profileViewController)
        #endif
        
        if viewControllers.count > 1 {
            let tabBarController = UITabBarController()
            Self.configuredTabBarController(tabBarController: tabBarController)
            tabBarController.viewControllers = viewControllers
            return tabBarController
        }
        else {
            return viewControllers.first
        }
    }
    
    private func setupAppCenter() {
        guard let appCenterSecret = Bundle.main.object(forInfoDictionaryKey: "AppCenterSecret") as? String, !appCenterSecret.isEmpty else { return }
        AppCenter.start(withAppSecret: appCenterSecret, services: [Crashes.self])
    }
    
    // MARK: - UIApplicationDelegate protocol
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
        application.accessibilityLanguage = configuration.voiceOverLanguageCode;
        
        if let identityWebserviceURL = configuration.identityWebserviceURL,
           let identityWebsiteURL = configuration.identityWebsiteURL {
            SRGIdentityService.current = SRGIdentityService(webserviceURL: identityWebserviceURL, websiteURL: identityWebsiteURL)
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
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        self.window = window
        
        let rootViewController = applicationRootViewController()!
        rootViewController.view.backgroundColor = (UIScreen.main.traitCollection.userInterfaceStyle == .dark) ? .play_black : .play_lightGray
        window.rootViewController = rootViewController
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            Self.configuredTabBarController(tabBarController: tabBarController)
        }
    }
    
    // See URL_SCHEMES.md
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let deeplinkAction = url.host else { return false }
        
        if deeplinkAction == "media" {
            let mediaUrn = url.lastPathComponent
            SRGDataProvider.current?.media(withUrn: mediaUrn)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                }, receiveValue: { media, _ in
                    navigateToMedia(media)
                })
                .store(in: &cancellables)
            return true
        }
        else if deeplinkAction == "show" {
            let showUrn = url.lastPathComponent
            SRGDataProvider.current?.show(withUrn: showUrn)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                }, receiveValue: { show, _ in
                    navigateToShow(show)
                })
                .store(in: &cancellables)
            return true
        }
        return false
    }
}
