//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UIWindow {
    var isLandscape: Bool {
        #if os(iOS)
            return bounds.width > bounds.height
        #else
            return true
        #endif
    }

    /**
     *  Return the topmost view controller (either root view controller or presented modally)
     */
    @objc var play_topViewController: UIViewController? {
        return rootViewController?.play_top
    }

    /**
     *  Dismiss all presented view controllers.
     */
    @objc func play_dismissAllViewControllers(animated: Bool, completion: (() -> Void)? = nil) {
        rootViewController?.dismiss(animated: animated, completion: completion)
    }
}
