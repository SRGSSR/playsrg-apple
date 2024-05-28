//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit
import SRGAppearance
import Tabman
import Pageboy

class PageContainerViewController: UIViewController {
    let viewControllers: [UIViewController]
    
    private let tabManVC = TabmanViewController()
    private(set) var initialPage: Int
    private weak var tabBarTopConstraint: NSLayoutConstraint!
    private let tabBarItems: [TMBarItem]
    
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
        
        super.init(nibName: nil, bundle: nil)
        let bar = TMBarView<TMHorizontalBarLayout, TMTabItemBarButton, TMLineBarIndicator>()
        bar.backgroundView.style = .flat(color: .srgGray16)
        bar.layout.alignment = .centerDistributed
        bar.indicator.tintColor = .white
        tabManVC.dataSource = self
        tabManVC.addBar(bar, dataSource: self, at: .top)
        bar.buttons.customize { button in
            button.contentMode = .scaleAspectFit
            button.imageContentMode = .scaleAspectFit
        }

        self.addChild(tabManVC)
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
        
        let pageView = tabManVC.view!
        view.insertSubview(pageView, at: 0)
        
        pageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: view.topAnchor),
            pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tabManVC.didMove(toParent: self)
        self.view = view
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
            tabManVC.pageboyParent?.scrollToPage(.at(index: index), animated: animated)
            return true
        }
        else {
            initialPage = index
            return true
        }
    }
    
    func didDisplayViewController(_ viewController: UIViewController, animated: Bool) {}
}

// MARK: - Protocols

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
        return viewControllers.first
    }
}

extension PageContainerViewController: SRGAnalyticsContainerViewTracking {
    var srg_activeChildViewControllers: [UIViewController] {
        return [tabManVC]
    }
}

extension PageContainerViewController: TabBarActionable {
    func performActiveTabAction(animated: Bool) {
        if let currentViewController = tabManVC.currentViewController,
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
