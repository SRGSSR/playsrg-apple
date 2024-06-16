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
            return UIImage(resource: .youthProtectionYellow)
        case .red:
            return UIImage(resource: .youthProtectionRed)
        default:
            return nil
        }
    }

    /**
     *  Return the standard image to be used for a given blocking reason, if any.
     */
    static func image(for blockingReason: SRGBlockingReason) -> UIImage? {
        switch blockingReason {
        case .geoblocking:
            return UIImage(resource: .geoblocked)
        case .legal:
            return UIImage(resource: .legal)
        case .ageRating12, .ageRating18:
            return UIImage(resource: .ageRating)
        case .startDate, .endDate, .none:
            return nil
        default:
            return UIImage(resource: .genericBlocked)
        }
    }
}
