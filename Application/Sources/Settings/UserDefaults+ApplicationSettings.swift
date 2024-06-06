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
        return dictionary(forKey: PlaySRG.PlaySRGSettingSelectedLivestreamURNForChannels)
    }
    
    @objc dynamic var PlaySRGSettingPosterImages: String? {
        return string(forKey: PlaySRG.PlaySRGSettingPosterImages)
    }
    
    @objc dynamic var PlaySRGSettingSquareImages: String? {
        return string(forKey: PlaySRG.PlaySRGSettingSquareImages)
    }
    
    @objc dynamic var PlaySRGSettingAudioHomepageOption: String? {
        return string(forKey: PlaySRG.PlaySRGSettingAudioHomepageOption)
    }
    
    @objc dynamic var PlaySRGSettingServiceIdentifier: String? {
        return string(forKey: PlaySRG.PlaySRGSettingServiceIdentifier)
    }
    
    @objc dynamic var PlaySRGSettingUserLocation: String? {
        return string(forKey: PlaySRG.PlaySRGSettingUserLocation)
    }
    
#if DEBUG || NIGHTLY || BETA
    @objc dynamic var PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled: Bool {
        return bool(forKey: PlaySRG.PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled)
    }
#endif
}
