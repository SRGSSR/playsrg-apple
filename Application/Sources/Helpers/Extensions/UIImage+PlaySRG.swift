//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

extension UIImage {
    /**
     *  Return youth protection image associated with a color, if any.
     */
    @objc static func image(for youthProtectionColor: SRGYouthProtectionColor) -> UIImage? {
        switch youthProtectionColor {
        case .yellow:
            UIImage(resource: .youthProtectionYellow)
        case .red:
            UIImage(resource: .youthProtectionRed)
        default:
            nil
        }
    }

    /**
     *  Return the standard image to be used for a given blocking reason, if any.
     */
    static func image(for blockingReason: SRGBlockingReason) -> UIImage? {
        switch blockingReason {
        case .geoblocking:
            UIImage(resource: .geoblocked)
        case .legal:
            UIImage(resource: .legal)
        case .ageRating12, .ageRating18:
            UIImage(resource: .ageRating)
        case .startDate, .endDate, .none:
            nil
        default:
            UIImage(resource: .genericBlocked)
        }
    }
}
