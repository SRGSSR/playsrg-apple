//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Firebase
import SRGDataProvider
import SwiftUI
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
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
            liveViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Live", comment: "Live tab title"), image: nil, tag: 2)
            viewControllers.append(liveViewController)
        }
        
        let searchViewController = UIHostingController(rootView: SearchView())
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 3)
        viewControllers.append(searchViewController)
        
        let profileViewController = UIHostingController(rootView: ProfileView())
        profileViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Profile", comment: "Profile tab title"), image: nil, tag: 4)
        viewControllers.append(profileViewController)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = viewControllers
        window.rootViewController = tabBarController
        return true
    }
}
