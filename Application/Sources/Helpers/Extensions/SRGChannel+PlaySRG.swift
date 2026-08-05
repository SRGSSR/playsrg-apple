//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension SRGChannel {
    var play_logoImage: UIImage? {
        if transmission == .radio {
            let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: uid)
            if ApplicationConfiguration.shared.isAudioContentHomepagePreferred {
                return RadioChannelSquareLogoImage(radioChannel)
            } else {
                return RadioChannelLogoImage(radioChannel)
            }
        } else {
            return TVChannelLogoImage(ApplicationConfiguration.shared.tvChannel(forUid: uid))
        }
    }

    var play_largeLogoImage: UIImage? {
        if transmission == .radio {
            let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: uid)
            if ApplicationConfiguration.shared.isAudioContentHomepagePreferred {
                return RadioChannelSquareLargeLogoImage(radioChannel)
            } else {
                return RadioChannelLargeLogoImage(radioChannel)
            }
        } else {
            return TVChannelLargeLogoImage(ApplicationConfiguration.shared.tvChannel(forUid: uid))
        }
    }
}
