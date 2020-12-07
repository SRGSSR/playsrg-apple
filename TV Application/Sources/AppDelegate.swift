//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Firebase
import SRGAnalytics
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
        
        let activeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.srg_color(fromHexadecimalString: "#161616")!]
        itemAppearance.selected.titleTextAttributes = activeTitleTextAttributes
        itemAppearance.focused.titleTextAttributes = activeTitleTextAttributes
        
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
        
        #if DEBUG
        let searchViewController = UIHostingController(rootView: SearchView())
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 3)
        viewControllers.append(searchViewController)
        
        let profileViewController = UIHostingController(rootView: ProfileView())
        profileViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Profile", comment: "Profile tab title"), image: nil, tag: 4)
        viewControllers.append(profileViewController)
        
        let historyViewController = UIHostingController(rootView: HistoryView())
        historyViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("History", comment: "Profile tab title"), image: nil, tag: 4)
        viewControllers.append(historyViewController)
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
    
    // MARK: - UIApplicationDelegate protocol
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        
        let configuration = ApplicationConfiguration.shared
        application.accessibilityLanguage = configuration.voiceOverLanguageCode;
        
        let cachesDirectoryUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
        let storeFileUrl = cachesDirectoryUrl.appendingPathComponent("PlayData.sqlite")
        SRGUserData.current = SRGUserData(storeFileURL: storeFileUrl, serviceURL: configuration.userDataServiceURL, identityService: nil)
        
        let analyticsConfiguration = SRGAnalyticsConfiguration(businessUnitIdentifier: configuration.analyticsBusinessUnitIdentifier,
                                                               container: configuration.analyticsContainer,
                                                               siteName: configuration.tvSiteName,
                                                               netMetrixIdentifier: configuration.netMetrixIdentifier)
        #if DEBUG || NIGHLTY || BETA
        analyticsConfiguration.environmentMode = .preProduction
        #endif
        SRGAnalyticsTracker.shared.start(with: analyticsConfiguration)
        
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
