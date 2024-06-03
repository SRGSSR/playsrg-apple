//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Pageboy
import UIKit
import SRGAppearance
import Tabman

class PageContainerViewController: UIViewController {
    let viewControllers: [UIViewController]
    
    private var tabContainerViewController: TabContainerViewController!
    private(set) var initialPage: Int
    private weak var tabBarTopConstraint: NSLayoutConstraint?
    private let tabBarItems: [TMBarItem]
    private let blurView: UIVisualEffectView
    
    init(viewControllers: [UIViewController], initialPage: Int) {
        assert(!viewControllers.isEmpty, "At least one view controller is required")
        
        self.viewControllers = viewControllers
        if initialPage >= 0 && initialPage < viewControllers.count {
            self.initialPage = initialPage
        } else {
            PlayLogWarning(category: "pageViewController", message: "Invalid page. Fixed to 0")
            self.initialPage = 0
        }
        
        self.tabBarItems = viewControllers.compactMap { $0.tabBarItem.image }.map { TMBarItem(image: $0) }
        self.blurView = UIVisualEffectView.play_blurView
        blurView.alpha = 0.0

        super.init(nibName: nil, bundle: nil)
        
        self.tabContainerViewController = TabContainerViewController(pageContainerViewController: self)
        configureBar()
        self.addChild(tabContainerViewController)
    }
    
    convenience init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, initialPage: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureBar() {
        let barView = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        barView.backgroundView.style = .custom(view: blurView)
        barView.layout.alignment = .centerDistributed
        barView.indicator.tintColor = .white
        tabContainerViewController.dataSource = self
        tabContainerViewController.addBar(barView, dataSource: self, at: .top)
        barView.buttons.customize { button in
            button.contentMode = .scaleAspectFit
            button.imageContentMode = .scaleAspectFit
        }
    }
    
    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let tabView = tabContainerViewController.view!
        view.insertSubview(tabView, at: 0)
        
        tabView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        tabBarTopConstraint = topConstraint
        NSLayoutConstraint.activate([
            topConstraint,
            tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tabContainerViewController.didMove(toParent: self)
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        didDisplayViewController(tabContainerViewController.currentViewController, animated: false)
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
    
    func didDisplayViewController(_ viewController: UIViewController?, animated: Bool) {}
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
    
    func play_contentOffsetDidChange(inScrollableView scrollView: UIScrollView) {
        let adjustedOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        tabBarTopConstraint?.constant = max(-adjustedOffset, 0.0)
        blurView.alpha = max(0.0, min(1.0, adjustedOffset / LayoutBlurActivationDistance))
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
