//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// Extensions allowing the use of KVO to detect user default changes by key.
// See https://stackoverflow.com/a/47856467/760435
extension UserDefaults {
    @objc dynamic var PlaySRGSettingSelectedLivestreamURNForChannels: [String: Any]? {
        dictionary(forKey: PlaySRG.PlaySRGSettingSelectedLivestreamURNForChannels)
    }

    @objc dynamic var PlaySRGSettingPosterImages: String? {
        string(forKey: PlaySRG.PlaySRGSettingPosterImages)
    }

    @objc dynamic var PlaySRGSettingPodcastImages: String? {
        string(forKey: PlaySRG.PlaySRGSettingPodcastImages)
    }

    @objc dynamic var PlaySRGSettingAudioHomepageOption: String? {
        string(forKey: PlaySRG.PlaySRGSettingAudioHomepageOption)
    }

    @objc dynamic var PlaySRGSettingServiceEnvironment: String? {
        string(forKey: PlaySRG.PlaySRGSettingServiceEnvironment)
    }

    @objc dynamic var PlaySRGSettingUserLocation: String? {
        string(forKey: PlaySRG.PlaySRGSettingUserLocation)
    }

    @objc dynamic var PlaySRGSettingProxyDetection: String? {
        string(forKey: PlaySRG.PlaySRGSettingProxyDetection)
    }

    #if DEBUG || NIGHTLY || BETA
        @objc dynamic var PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled: Bool {
            bool(forKey: PlaySRG.PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled)
        }
    #endif
}
