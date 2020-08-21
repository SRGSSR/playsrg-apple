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
        
        let videosView = UIHostingController(rootView: VideosView())
        videosView.tabBarItem = UITabBarItem(title: NSLocalizedString("Videos", comment: "Videos tab title"), image: nil, tag: 0)
        
        let audiosView = UIHostingController(rootView: AudiosView())
        audiosView.tabBarItem = UITabBarItem(title: NSLocalizedString("Audios", comment: "Audios tab title"), image: nil, tag: 1)
        
        let liveView = UIHostingController(rootView: LiveView())
        liveView.tabBarItem = UITabBarItem(title: NSLocalizedString("Live", comment: "Live tab title"), image: nil, tag: 2)
        
        let searchView = UIHostingController(rootView: SearchView())
        searchView.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 3)
        
        let profileView = UIHostingController(rootView: ProfileView())
        profileView.tabBarItem = UITabBarItem(title: NSLocalizedString("Profile", comment: "Profile tab title"), image: nil, tag: 4)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [videosView, audiosView, liveView, searchView, profileView]
        window.rootViewController = tabBarController
        return true
    }
}
