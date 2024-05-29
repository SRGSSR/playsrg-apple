//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit
import Pageboy
import Tabman

final class TabContainerViewController: TabmanViewController {
    private weak var pageContainerViewController: PageContainerViewController?
    
    convenience init(pageContainerViewController: PageContainerViewController) {
        self.init()
        self.pageContainerViewController = pageContainerViewController
    }
    
    override func pageboyViewController(_ pageboyViewController: Pageboy.PageboyViewController, didScrollTo position: CGPoint, direction: Pageboy.PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollTo: position, direction: direction, animated: animated)
        pageContainerViewController?.didDisplayViewController(currentViewController, animated: animated)
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: PageboyViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        pageContainerViewController?.didDisplayViewController(currentViewController, animated: animated)
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didReloadWith currentViewController: UIViewController, currentPageIndex: PageboyViewController.PageIndex) {
        super.pageboyViewController(pageboyViewController, didReloadWith: currentViewController, currentPageIndex: currentPageIndex)
        pageContainerViewController?.didDisplayViewController(currentViewController, animated: false)
    }
}
