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
    
    private var tabContainerViewController: TabContainerViewController
    private(set) var initialPage: Int
    private let tabBarItems: [TMBarItem]
    private weak var tabBarTopConstraint: NSLayoutConstraint?
    private weak var blurView: UIVisualEffectView?
    private var cancellables: Set<AnyCancellable> = []

    init(viewControllers: [UIViewController], initialPage: Int) {
        assert(!viewControllers.isEmpty, "At least one view controller is required")
        
        self.viewControllers = viewControllers
        if initialPage >= 0 && initialPage < viewControllers.count {
            self.initialPage = initialPage
        } else {
            PlayLogWarning(category: "pageViewController", message: "Invalid page. Fixed to 0")
            self.initialPage = 0
        }
        
        self.tabBarItems = viewControllers.map {
            if let tabBarItem = $0.tabBarItem, let image = tabBarItem.image {
                let item = TMBarItem(image: image)
                item.accessibilityLabel = tabBarItem.title ?? $0.title
                return item
            }
            else {
                let item = TMBarItem(title: $0.title ?? "")
                item.accessibilityLabel = $0.title
                return item
            }
        }
        
        self.tabContainerViewController = TabContainerViewController()

        super.init(nibName: nil, bundle: nil)
        
        self.addChild(tabContainerViewController)
    }
    
    convenience init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, initialPage: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureBarView() {
        let blurView = UIVisualEffectView.play_blurView
        self.blurView = blurView
        
        let barView = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        barView.backgroundView.style = .custom(view: blurView)
        barView.layout.alignment = .centerDistributed
        barView.indicator.tintColor = .white
        barView.buttons.customize { button in
            button.imageContentMode = .center
        }
        tabContainerViewController.addBar(barView, dataSource: self, at: .top)
    }
    
    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        self.view = view
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
        return .lightContent
    }
    
    override func accessibilityPerformEscape() -> Bool {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
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
        
        if self.isViewLoaded {
            tabContainerViewController.scrollToPage(.at(index: index), animated: animated)
            didDisplayViewController(tabContainerViewController.currentViewController, animated: animated)
            return true
        }
        else {
            initialPage = index
            return true
        }
    }
    
    func didDisplayViewController(_ viewController: UIViewController?, animated: Bool) {
        play_setNeedsScrollableViewUpdate()
    }
}

// MARK: - Protocols

extension PageContainerViewController: ContainerContentInsets {
    var play_additionalContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: tabContainerViewController.barInsets.top, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

extension PageContainerViewController: Oriented {
    var play_supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    var play_orientingChildViewControllers: [UIViewController] {
        return viewControllers
    }
}

extension PageContainerViewController: ScrollableContentContainer {
    var play_scrollableChildViewController: UIViewController? {
        tabContainerViewController.currentViewController
    }
}

extension PageContainerViewController: SRGAnalyticsContainerViewTracking {
    var srg_activeChildViewControllers: [UIViewController] {
        return [tabContainerViewController]
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
        var parentViewController = self.parent
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
    func numberOfViewControllers(in pageboyViewController: Pageboy.PageboyViewController) -> Int {
        viewControllers.count
    }
    
    func viewController(for pageboyViewController: Pageboy.PageboyViewController, at index: Pageboy.PageboyViewController.PageIndex) -> UIViewController? {
        viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: Pageboy.PageboyViewController) -> Pageboy.PageboyViewController.Page? {
        .at(index: initialPage)
    }
    
    func barItem(for bar: any Tabman.TMBar, at index: Int) -> any Tabman.TMBarItemable {
        tabBarItems[index]
    }
}
