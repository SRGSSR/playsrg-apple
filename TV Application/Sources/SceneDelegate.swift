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
        appearance.configureWithDefaultBackground()
        
        appearance.backgroundColor = .srgGray23
        appearance.selectionIndicatorTintColor = .srgGray96
        
        let font: UIFont = SRGFont.font(family: .text, weight: .medium, size: 28)
        let normalColor = UIColor.white
        let activeColor = UIColor.srgGray16
        
        let normalItemAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: normalColor
        ]
        let activeItemAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: activeColor
        ]
        
        let inlineItemAppearance = UITabBarItemAppearance(style: .inline)
        inlineItemAppearance.normal.titleTextAttributes = normalItemAttributes
        inlineItemAppearance.normal.iconColor = normalColor
        inlineItemAppearance.selected.titleTextAttributes = activeItemAttributes
        inlineItemAppearance.selected.iconColor = activeColor
        inlineItemAppearance.focused.titleTextAttributes = activeItemAttributes
        inlineItemAppearance.focused.iconColor = activeColor
        appearance.inlineLayoutAppearance = inlineItemAppearance
        
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
    
    private func handleURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        // FIXME: Works as long as only one context is received
        guard let urlContext = urlContexts.first else { return }
        
        actionFromURL(urlContext.url)
    }
    
    private func openMedia(withUrn urn: String, play: Bool) {
        SRGDataProvider.current?.media(withUrn: urn)
            .receive(on: DispatchQueue.main)
            .sink { _ in
            } receiveValue: { media in
                navigateToMedia(media, play: play)
            }
            .store(in: &cancellables)
    }
    
    /**
     *  Describes a deep link action (also see CUSTOM_URLS_AND_UNIVERSAL_LINKS.md). The list of supported URLs currently includes:
     *
     *    [scheme]://media/[media_urn]
     *    [scheme]://play/[media_urn]
     *    [scheme]://show/[show_urn]
     */
    private func actionFromURL(_ url: URL) {
        guard let deeplLinkAction = url.host else { return }
        
        if deeplLinkAction == "media" {
            let mediaUrn = url.lastPathComponent
            openMedia(withUrn: mediaUrn, play: false)
        }
        else if deeplLinkAction == "play" {
            let mediaUrn = url.lastPathComponent
            openMedia(withUrn: mediaUrn, play: true)
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
        }
    }
}

extension SceneDelegate: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window!.makeKeyAndVisible()
        window!.rootViewController = applicationRootViewController()
        
        handleURLContexts(connectionOptions.urlContexts)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURLContexts(URLContexts)
    }
}
