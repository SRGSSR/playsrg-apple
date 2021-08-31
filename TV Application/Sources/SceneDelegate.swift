//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI
import UIKit

class SceneDelegate: UIResponder {
    var window: UIWindow?
    
    private static func configureTabBarController(_ tabBarController: UITabBarController) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .srgGray23
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
        tabBarController.view.backgroundColor = .srgGray16
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
            let showsViewController = SectionViewController.showsViewController(forChannelUid: nil)
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
        profileViewController.tabBarItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Profile", comment: "Profile button label on home view")
        profileViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.profileTabBarItem.rawValue
        viewControllers.append(profileViewController)
        
        if viewControllers.count > 1 {
            let tabBarController = UITabBarController()
            Self.configureTabBarController(tabBarController)
            tabBarController.viewControllers = viewControllers
            return tabBarController
        }
        else {
            return viewControllers.first!
        }
    }
}

extension SceneDelegate: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window!.makeKeyAndVisible()
        window!.rootViewController = applicationRootViewController()
    }
}

