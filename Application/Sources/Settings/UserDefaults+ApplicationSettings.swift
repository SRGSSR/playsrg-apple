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

    @objc dynamic var PlaySRGSettingSquareImages: String? {
        string(forKey: PlaySRG.PlaySRGSettingSquareImages)
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

    #if DEBUG || NIGHTLY || BETA
        @objc dynamic var PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled: Bool {
            bool(forKey: PlaySRG.PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled)
        }
    #endif
}
