//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UIWindow {
    var isLandscape: Bool {
#if os(iOS)
        return self.bounds.width > self.bounds.height
#else
        return true
#endif
    }
}
