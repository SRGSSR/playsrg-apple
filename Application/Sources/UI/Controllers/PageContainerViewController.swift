//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit
import SRGAppearance

class PageContainerViewController: UIViewController {
    let viewControllers: [UIViewController]
    let initialPage: Int
    
    private var pageViewController: UIPageViewController
    
    private var tabBar: MDCTabBar!
    private var blurView: UIVisualEffectView!
    private var tabBarTopConstraint: NSLayoutConstraint!
    
    init(viewControllers: [UIViewController], initialPage: Int) {
        assert(!viewControllers.isEmpty, "At least one view controller is required")
        
        self.viewControllers = viewControllers
        if initialPage >= 0 && initialPage < viewControllers.count {
            self.initialPage = initialPage
        } else {
            PlayLogWarning(category: "pageViewController", message: "Invalid page. Fixed to 0")
            self.initialPage = 0
        }
        
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 100.0])
        self.pageViewController = pageViewController
        
        super.init(nibName: nil, bundle: nil)
        
        pageViewController.delegate = self
        
        // Only allow scrolling if several pages are available
        if viewControllers.count > 1 {
            pageViewController.dataSource = self
        }
        self.addChild(pageViewController)
    }
    
    convenience init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, initialPage: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .srgGray16
        
        let pageView = pageViewController.view!
        view.insertSubview(pageView, at: 0)
        
        pageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: view.topAnchor),
            pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        pageViewController.didMove(toParent: self)
        
        var hasImage = false
        var tabBarItems = [UITabBarItem]()
        viewControllers.forEach { viewController in
            if let tabBarItem = viewController.tabBarItem {
                tabBarItems.append(tabBarItem)
                if tabBarItem.image != nil {
                    hasImage = true
                }
            }
        }
        
        let tabBar = MDCTabBar()
        tabBar.itemAppearance = hasImage ? .images : .titles
        tabBar.alignment = .center
        tabBar.delegate = self
        tabBar.items = tabBarItems
        
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = .srgGray96
        tabBar.selectedItemTintColor = .white
        
        // Use ripple effect without color, so that there is no Material-like highlighting (we are NOT adopting Material)
        tabBar.enableRippleBehavior = true
        tabBar.rippleColor = .clear
        
        view.addSubview(tabBar)
        self.tabBar = tabBar
        
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBarTopConstraint = tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            tabBarTopConstraint,
            tabBar.heightAnchor.constraint(equalToConstant: 60.0),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let blurView = UIVisualEffectView.play_blurView
        blurView.alpha = 0.0
        view.insertSubview(blurView, belowSubview: tabBar)
        self.blurView = blurView
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        self.view = view
        self.updateFonts()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.selectedItem = tabBar.items[initialPage]
        let initialViewController = viewControllers[initialPage]
        pageViewController.setViewControllers([initialViewController], direction: .forward, animated: false, completion: nil)
        didDisplayViewController(initialViewController, animated: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Force a refresh of the tab bar so that the alignment is correct after rotation
            self.tabBar.alignment = .leading
            self.tabBar.alignment = .center
        }, completion: nil)
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
        guard displayPage(at: index, animated: animated) else { return false }
        
        tabBar.setSelectedItem(tabBar.items[index], animated: animated)
        return true
    }
    
    func displayPage(at index: Int, animated: Bool) -> Bool {
        guard index < viewControllers.count else { return false }
        
        let currentViewController = pageViewController.viewControllers!.first!
        let currentIndex = viewControllers.firstIndex(of: currentViewController)!
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        
        let newViewController = viewControllers[index]
        pageViewController.setViewControllers([newViewController], direction: direction, animated: animated)
        self.play_setNeedsScrollableViewUpdate()
        
        didDisplayViewController(newViewController, animated: animated)
        return true
    }
    
    func updateFonts() {
        let tabBarFont = SRGFont.font(.body) as UIFont
        tabBar.unselectedItemTitleFont = tabBarFont
        tabBar.selectedItemTitleFont = tabBarFont
    }
    
    @objc func contentSizeCategoryDidChange(_ notification: Notification) {
        updateFonts()
    }
    
    func didDisplayViewController(_ viewController: UIViewController, animated: Bool) {}
}

// MARK: - Protocols

extension PageContainerViewController: ContainerContentInsets {
    var play_additionalContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: blurView.frame.height, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

extension PageContainerViewController: MDCTabBarDelegate {
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items.firstIndex(of: item) {
            _ = displayPage(at: index, animated: true)
        }
    }
}

extension PageContainerViewController: Oriented {
    var play_supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    var play_orientingChildViewControllers: [UIViewController] {
        return pageViewController.viewControllers ?? []
    }
}

extension PageContainerViewController: ScrollableContentContainer {
    var play_scrollableChildViewController: UIViewController? {
        return pageViewController.viewControllers?.first
    }
    
    func play_contentOffsetDidChange(inScrollableView scrollView: UIScrollView) {
        let adjustedOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        tabBarTopConstraint.constant = max(-adjustedOffset, 0.0)
        blurView.alpha = max(0.0, min(1.0, adjustedOffset / LayoutBlurActivationDistance))
    }
}

extension PageContainerViewController: SRGAnalyticsContainerViewTracking {
    var srg_activeChildViewControllers: [UIViewController] {
        return [pageViewController]
    }
}

extension PageContainerViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let actionableCurrentViewController = currentViewController as? TabBarActionable {
            actionableCurrentViewController.performActiveTabAction(animated: animated)
        }
    }
}

extension PageContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.firstIndex(of: viewController), index > 0 {
            return viewControllers[index - 1]
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.firstIndex(of: viewController), index < viewControllers.count - 1 {
            return viewControllers[index + 1]
        }
        return nil
    }
}

extension PageContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            guard let newViewController = pageViewController.viewControllers?.first else { return }
            guard let currentIndex = viewControllers.firstIndex(of: newViewController) else { return }
            tabBar.setSelectedItem(tabBar.items[currentIndex], animated: true)
            didDisplayViewController(newViewController, animated: true)
            play_setNeedsScrollableViewUpdate()
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
