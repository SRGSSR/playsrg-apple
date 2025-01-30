//
//  ShowAccessContainerViewController.swift
//  PlaySRG
//
//  Created by Mustapha Tarek BEN LECHHAB on 30.01.2025.
//  Copyright © 2025 SRG SSR. All rights reserved.
//

import Pageboy
import Tabman
import UIKit

final class ShowAccessContainerViewController: UIViewController {
    private let radioChannels: [RadioChannel]
    private let tabContainerViewController: TabContainerViewController
    private let tabBarItems: [TMBarItem]
    private let viewControllers: [SectionViewController]

    init(radioChannels: [RadioChannel]) {
        self.radioChannels = radioChannels
        tabContainerViewController = TabContainerViewController()

        var items: [UITabBarItem] = []

        for (index, radioChannel) in radioChannels.enumerated() {
            items.append(UITabBarItem(title: radioChannel.name, image: RadioChannelLogoImage(radioChannel), tag: index))
        }

        tabBarItems = items.map { item in
            if let image = item.image {
                let tmBarItem = TMBarItem(image: image)
                tmBarItem.accessibilityLabel = item.title
                return tmBarItem
            } else {
                let tmBarItem = TMBarItem(title: item.title ?? "")
                tmBarItem.accessibilityLabel = item.title
                return tmBarItem
            }
        }

        viewControllers = radioChannels.map { radioChannel in
            SectionViewController(section: .configured(.radioAllShows(channelUid: radioChannel.uid)))
        }

        super.init(nibName: nil, bundle: nil)
        addChild(tabContainerViewController)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureBarView() {
        let barView = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        barView.backgroundView.style = .flat(color: .srgGray16)
        barView.layout.alignment = .centerDistributed
        barView.indicator.tintColor = .white
        tabContainerViewController.addBar(barView, dataSource: self, at: .top)
    }

    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBarView()
        if let tabContainerView = tabContainerViewController.view {
            view.insertSubview(tabContainerView, at: 0)

            tabContainerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tabContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tabContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tabContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        tabContainerViewController.didMove(toParent: self)
        tabContainerViewController.dataSource = self
    }
}

// MARK: - Protocols

extension ShowAccessContainerViewController: ContainerContentInsets {
    var play_additionalContentInsets: UIEdgeInsets {
        UIEdgeInsets(top: tabContainerViewController.barInsets.top, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

extension ShowAccessContainerViewController: Oriented {
    var play_supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    var play_orientingChildViewControllers: [UIViewController] {
        viewControllers
    }
}

extension ShowAccessContainerViewController: SRGAnalyticsContainerViewTracking {
    var srg_activeChildViewControllers: [UIViewController] {
        [tabContainerViewController]
    }
}

extension ShowAccessContainerViewController: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in _: Pageboy.PageboyViewController) -> Int {
        viewControllers.count
    }

    func viewController(for _: Pageboy.PageboyViewController, at index: Pageboy.PageboyViewController.PageIndex) -> UIViewController? {
        viewControllers[index]
    }

    func defaultPage(for _: Pageboy.PageboyViewController) -> Pageboy.PageboyViewController.Page? {
        .at(index: 0)
    }

    func barItem(for _: any Tabman.TMBar, at index: Int) -> any Tabman.TMBarItemable {
        tabBarItems[index]
    }
}
