//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Pageboy
import UIKit
import Tabman

final class TabContainerViewController: TabmanViewController {
    weak var pageContainerViewController: PageContainerViewController?
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: PageboyViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        pageContainerViewController?.didDisplayViewController(currentViewController, animated: animated)
        pageContainerViewController?.play_setNeedsScrollableViewUpdate()
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didReloadWith currentViewController: UIViewController, currentPageIndex: PageboyViewController.PageIndex) {
        super.pageboyViewController(pageboyViewController, didReloadWith: currentViewController, currentPageIndex: currentPageIndex)
        pageContainerViewController?.didDisplayViewController(currentViewController, animated: false)
    }
}
