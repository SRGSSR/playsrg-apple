//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension ButtonStyle {
    static func focusedScaleFactor(for unfocusedSize: CGSize) -> CGFloat {
        let maxDimension = max(unfocusedSize.width, unfocusedSize.height)
        guard maxDimension != 0 else { return 1 }
        return (maxDimension + 40) / maxDimension
    }
}
