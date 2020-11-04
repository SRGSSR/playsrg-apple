//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UIWindow {
    var topViewController: UIViewController? {
        return rootViewController?.topViewController
    }
}

extension UIViewController {
    var topViewController: UIViewController {
        var topViewController = self
        while let topPresentedViewController = topViewController.presentedViewController {
            topViewController = topPresentedViewController
        }
        return topViewController
    }
}
