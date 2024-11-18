//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Pageboy
import SRGAppearance
import Tabman
import UIKit

class PageContainerViewController: UIViewController {
    let viewControllers: [UIViewController]
    private let additionalViewControllers: [UIViewController]

    private var tabContainerViewController: TabContainerViewController
    private(set) var initialPage: Int
    private let tabBarItems: [TMBarItem]
    private weak var tabBarTopConstraint: NSLayoutConstraint?
    private weak var blurView: UIVisualEffectView?
    private var cancellables: Set<AnyCancellable> = []
    private var satelliteRadioChannels: [RadioChannel] = []
    private var cancellable: AnyCancellable?

    init(viewControllers: [UIViewController], additionalViewControllers: [UIViewController], satelliteRadioChannels: [RadioChannel], initialPage: Int) {
        assert(!viewControllers.isEmpty, "At least one view controller is required")

        self.viewControllers = viewControllers
        self.additionalViewControllers = additionalViewControllers
        self.satelliteRadioChannels = satelliteRadioChannels

        if initialPage >= 0, initialPage < viewControllers.count {
            self.initialPage = initialPage
        } else {
            PlayLogWarning(category: "pageViewController", message: "Invalid page. Fixed to 0")
            self.initialPage = 0
        }

        tabBarItems = viewControllers.appending(contentsOf: additionalViewControllers).map {
            if let tabBarItem = $0.tabBarItem, let image = tabBarItem.image {
                let item = TMBarItem(image: image)
                item.accessibilityLabel = tabBarItem.title ?? $0.title
                return item
            } else {
                let item = TMBarItem(title: $0.title ?? "")
                item.accessibilityLabel = $0.title
                return item
            }
        }

        tabContainerViewController = TabContainerViewController()

        super.init(nibName: nil, bundle: nil)

        addChild(tabContainerViewController)
    }

    convenience init(viewControllers: [UIViewController], additionalViewControllers: [UIViewController], satelliteRadioChannels: [RadioChannel]) {
        self.init(viewControllers: viewControllers, additionalViewControllers: additionalViewControllers, satelliteRadioChannels: satelliteRadioChannels, initialPage: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureBarView() {
        let blurView = UIVisualEffectView.play_blurView
        self.blurView = blurView

        let barView = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        barView.backgroundView.style = .custom(view: blurView)
        barView.layout.alignment = .centerDistributed
        barView.indicator.tintColor = .white

        var buttonIndex = 0
        barView.buttons.customize { [weak self] button in
            guard let self else { return }
            button.tag = buttonIndex
            button.imageContentMode = .center
            button.addTarget(self, action: #selector(tabDidChange(_:)), for: .touchUpInside)
            buttonIndex += 1
        }
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
            let tabBarTopConstraint = tabContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            NSLayoutConstraint.activate([
                tabBarTopConstraint,
                tabContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tabContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            self.tabBarTopConstraint = tabBarTopConstraint
        }
        tabContainerViewController.didMove(toParent: self)

        tabContainerViewController.dataSource = self
        didDisplayViewController(tabContainerViewController.currentViewController, animated: false)

        tabContainerViewController
            .updateSignal()
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                didDisplayViewController(tabContainerViewController.currentViewController, animated: false)
            }
            .store(in: &cancellables)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func accessibilityPerformEscape() -> Bool {
        if let navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
            return true
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
            return true
        } else {
            return false
        }
    }

    func switchToIndex(_ index: Int, animated: Bool) -> Bool {
        guard index < viewControllers.count else { return false }

        if isViewLoaded {
            tabContainerViewController.scrollToPage(.at(index: index), animated: animated)
            didDisplayViewController(tabContainerViewController.currentViewController, animated: animated)
            return true
        } else {
            initialPage = index
            return true
        }
    }

    func didDisplayViewController(_: UIViewController?, animated _: Bool) {
        play_setNeedsScrollableViewUpdate()
    }
}

// MARK: - Protocols

extension PageContainerViewController: ContainerContentInsets {
    var play_additionalContentInsets: UIEdgeInsets {
        UIEdgeInsets(top: tabContainerViewController.barInsets.top, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

extension PageContainerViewController: Oriented {
    var play_supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    var play_orientingChildViewControllers: [UIViewController] {
        viewControllers
    }
}

extension PageContainerViewController: ScrollableContentContainer {
    var play_scrollableChildViewController: UIViewController? {
        tabContainerViewController.currentViewController
    }

    func play_contentOffsetDidChange(inScrollableView scrollView: UIScrollView) {
        let adjustedOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        tabBarTopConstraint?.constant = max(-adjustedOffset, 0.0)
    }
}

extension PageContainerViewController: SRGAnalyticsContainerViewTracking {
    var srg_activeChildViewControllers: [UIViewController] {
        [tabContainerViewController]
    }
}

extension PageContainerViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        if let currentViewController = tabContainerViewController.currentViewController,
           let actionableCurrentViewController = currentViewController as? TabBarActionable {
            actionableCurrentViewController.performActiveTabAction(animated: animated)
        }
    }
}

extension UIViewController {
    var play_pageContainerViewController: PageContainerViewController? {
        var parentViewController = parent
        while let viewController = parentViewController {
            if let pageContainerViewController = viewController as? PageContainerViewController {
                return pageContainerViewController
            }
            parentViewController = viewController.parent
        }
        return nil
    }
}

extension PageContainerViewController: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in _: Pageboy.PageboyViewController) -> Int {
        viewControllers.count + additionalViewControllers.count
    }

    func viewController(for _: Pageboy.PageboyViewController, at index: Pageboy.PageboyViewController.PageIndex) -> UIViewController? {
        if index < viewControllers.count {
            viewControllers[index]
        } else {
            nil
        }
    }

    func defaultPage(for _: Pageboy.PageboyViewController) -> Pageboy.PageboyViewController.Page? {
        .at(index: initialPage)
    }

    func barItem(for _: any Tabman.TMBar, at index: Int) -> any Tabman.TMBarItemable {
        tabBarItems[index]
    }
}

// MARK: Swiss Satellite Radio

extension PageContainerViewController {
    func srgMedia(for radioChannel: RadioChannel) -> AnyPublisher<SRGMedia, Error> {
        SRGDataProvider.current!.regionalizedRadioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: .swissSatelliteRadio)
            .compactMap { $0.first { $0.uid == radioChannel.uid } }
            .eraseToAnyPublisher()
    }

    @objc private func tabDidChange(_ sender: TMTabItemBarButton) {
        if sender.tag >= viewControllers.count {
            cancellable = srgMedia(for: satelliteRadioChannels[sender.tag - viewControllers.count])
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] srgMedia in
                        self?.play_presentMediaPlayer(with: srgMedia, position: nil, airPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
                    }
                )
        }
    }
}
