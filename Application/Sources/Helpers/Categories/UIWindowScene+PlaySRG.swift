//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UIWindowScene {
    var isLandscape: Bool {
#if os(iOS)
        return interfaceOrientation.isLandscape
#else
        return true
#endif
    }
}
