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
    
    @objc dynamic var PlaySRGSettingServiceURL: String? {
        return string(forKey: PlaySRG.PlaySRGSettingServiceURL)
    }
    
    @objc dynamic var PlaySRGSettingUserLocation: String? {
        return string(forKey: PlaySRG.PlaySRGSettingUserLocation)
    }
}
