//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SRGDataProviderCombine
import SwiftUI
import UIKit

final class SceneDelegate: UIResponder {
    var window: UIWindow?

    private var cancellables = Set<AnyCancellable>()
    #if DEBUG || NIGHTLY || BETA
        private var settingUpdatesCancellables = Set<AnyCancellable>()
    #endif

    private static func configureTabBarController(_ tabBarController: UITabBarController) {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        appearance.backgroundColor = UIColor(white: 1, alpha: 0.1)
        appearance.backgroundEffect = UIBlurEffect(style: .dark)
        appearance.selectionIndicatorTintColor = .srgGray96

        let font: UIFont = SRGFont.font(family: .text, weight: .medium, fixedSize: 28)
        let normalColor = UIColor.white
        let activeColor = UIColor.srgGray16

        let normalItemAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: normalColor
        ]
        let activeItemAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: activeColor
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

    private static func applicationRootViewController() -> UIViewController {
        var viewControllers = [UIViewController]()

        let pageViewController = PageViewController(id: .video)
        pageViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Home", comment: "Home tab title"), image: nil, tag: 0)
        pageViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.videosTabBarItem.value
        viewControllers.append(pageViewController)

        let configuration = ApplicationConfiguration.shared

        #if DEBUG
            if ApplicationConfiguration.shared.isAudioContentHomepagePreferred {
                let pageViewController = PageViewController(id: .audio(channel: nil))
                pageViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Audios", comment: "Audios tab title"), image: nil, tag: 1)
                pageViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.audiosTabBarItem.value
                viewControllers.append(pageViewController)
            } else if let firstChannel = configuration.radioHomepageChannels.first {
                let pageViewController = PageViewController(id: .audio(channel: firstChannel))
                pageViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Audios", comment: "Audios tab title"), image: nil, tag: 1)
                pageViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.audiosTabBarItem.value
                viewControllers.append(pageViewController)
            }
        #endif

        if !configuration.liveHomeSections.isEmpty {
            let pageViewController = PageViewController(id: .live)
            pageViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Livestreams", comment: "Livestreams tab title"), image: nil, tag: 2)
            pageViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.livestreamsTabBarItem.value
            viewControllers.append(pageViewController)
        }

        if !configuration.isTvGuideUnavailable {
            let programGuideViewController = ProgramGuideViewController()
            programGuideViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("TV guide", comment: "TV program guide view title"), image: nil, tag: 3)
            programGuideViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.tvGuideTabBarItem.value
            viewControllers.append(programGuideViewController)
        }

        if !configuration.areShowsUnavailable {
            let showsViewController = SectionViewController.showsViewController(for: .TV, channelUid: nil)
            showsViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Shows", comment: "Shows tab title"), image: nil, tag: 4)
            showsViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.showsTabBarItem.value
            viewControllers.append(showsViewController)
        }

        let searchViewController = SearchViewController.viewController()
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Search", comment: "Search tab title"), image: nil, tag: 5)
        searchViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.searchTabBarItem.value
        viewControllers.append(searchViewController)

        let profileViewController = UIHostingController(rootView: SettingsView())
        profileViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(resource: .profileTab).withRenderingMode(.alwaysTemplate), tag: 6)
        profileViewController.tabBarItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString("Profile", comment: "Profile button label on home view")
        profileViewController.tabBarItem.accessibilityIdentifier = AccessibilityIdentifier.profileTabBarItem.value
        viewControllers.append(profileViewController)

        if viewControllers.count > 1 {
            let tabBarController = UITabBarController()
            Self.configureTabBarController(tabBarController)
            tabBarController.viewControllers = viewControllers
            return tabBarController
        } else {
            return viewControllers.first!
        }
    }

    private func handleURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        // FIXME: Works as long as only one context is received
        guard let urlContext = urlContexts.first else { return }

        let action = DeepLinkAction(from: urlContext)
        switch action.type {
        case .media:
            UserConsentHelper.waitCollectingConsentRetain()
            SRGDataProvider.current!.media(withUrn: action.identifier)
                .receive(on: DispatchQueue.main)
                .sink { result in
                    if case .failure = result {
                        UserConsentHelper.waitCollectingConsentRelease()
                    }
                } receiveValue: { media in
                    navigateToMedia(media)
                    action.analyticsEvent.send()
                    UserConsentHelper.waitCollectingConsentRelease()
                }
                .store(in: &cancellables)
        case .show:
            UserConsentHelper.waitCollectingConsentRetain()
            SRGDataProvider.current!.show(withUrn: action.identifier)
                .receive(on: DispatchQueue.main)
                .sink { result in
                    if case .failure = result {
                        UserConsentHelper.waitCollectingConsentRelease()
                    }
                } receiveValue: { show in
                    navigateToShow(show)
                    action.analyticsEvent.send()
                    UserConsentHelper.waitCollectingConsentRelease()
                }
                .store(in: &cancellables)
        case .page, .microPage:
            UserConsentHelper.waitCollectingConsentRetain()
            SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, uid: action.identifier)
                .receive(on: DispatchQueue.main)
                .sink { result in
                    if case .failure = result {
                        UserConsentHelper.waitCollectingConsentRelease()
                    }
                } receiveValue: { page in
                    navigateToPage(page)
                    action.analyticsEvent.send()
                    UserConsentHelper.waitCollectingConsentRelease()
                }
                .store(in: &cancellables)
        default:
            break
        }
    }
}

extension SceneDelegate: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        window.rootViewController = Self.applicationRootViewController()
        self.window = window

        handleURLContexts(connectionOptions.urlContexts)

        #if DEBUG || NIGHTLY || BETA
            Publishers.MergeMany(
                ApplicationSignal.settingUpdates(at: \.PlaySRGSettingPosterImages),
                ApplicationSignal.settingUpdates(at: \.PlaySRGSettingSquareImages),
                ApplicationSignal.settingUpdates(at: \.PlaySRGSettingAudioHomepageOption),
                ApplicationSignal.settingUpdates(at: \.PlaySRGSettingServiceEnvironment),
                ApplicationSignal.settingUpdates(at: \.PlaySRGSettingUserLocation)
            )
            .debounce(for: 0.7, scheduler: DispatchQueue.main)
            .sink {
                window.rootViewController = Self.applicationRootViewController()
            }
            .store(in: &settingUpdatesCancellables)
        #endif
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURLContexts(URLContexts)
    }
}
