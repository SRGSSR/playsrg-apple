//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Firebase
import SRGAppearance
import SRGDataProvider
import SwiftUI
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private static func configuredTabBarController(tabBarController: UITabBarController) {
        tabBarController.view.backgroundColor = (UIScreen.main.traitCollection.userInterfaceStyle == .dark) ? .play_black : .play_lightGray
        
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
    
    // MARK: - UIApplicationDelegate protocol
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            FirebaseApp.configure()
        }
        
        SRGDataProvider.current = SRGDataProvider(serviceURL: SRGIntegrationLayerProductionServiceURL())
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        self.window = window
        
        let configuration = ApplicationConfiguration.shared
        var viewControllers = [UIViewController]()
        
        let videosViewController = UIHostingController(rootView: VideosView())
        videosViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Videos", comment: "Videos tab title"), image: nil, tag: 0)
        viewControllers.append(videosViewController)
        
        if !configuration.radioChannels.isEmpty {
            let audiosViewController = UIHostingController(rootView: AudiosView())
            audiosViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Audios", comment: "Audios tab title"), image: nil, tag: 1)
            viewControllers.append(audiosViewController)
        }
        
        if !configuration.liveHomeSections.isEmpty {
            let liveViewController = UIHostingController(rootView: LiveView())
            liveViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), image: nil, tag: 2)
            viewControllers.append(liveViewController)
        }
        
        let showsViewController = UIHostingController(rootView: ShowsView())
        showsViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Shows", comment: "Shows tab title"), image: nil, tag: 3)
        viewControllers.append(showsViewController)
        
        let searchViewController = UIHostingController(rootView: SearchView())
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 3)
        viewControllers.append(searchViewController)
        
        let profileViewController = UIHostingController(rootView: ProfileView())
        profileViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Profile", comment: "Profile tab title"), image: nil, tag: 4)
        viewControllers.append(profileViewController)
        
        let tabBarController = UITabBarController()
        Self.configuredTabBarController(tabBarController: tabBarController)
        tabBarController.viewControllers = viewControllers
        window.rootViewController = tabBarController
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            Self.configuredTabBarController(tabBarController: tabBarController)
        }
    }
}
