//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension SRGChannel {
    var play_largeLogoImage: UIImage? {
        if transmission == .radio {
            RadioChannelLargeLogoImage(ApplicationConfiguration.shared.radioChannel(forUid: uid))
        } else {
            TVChannelLargeLogoImage(ApplicationConfiguration.shared.tvChannel(forUid: uid))
        }
    }
}
