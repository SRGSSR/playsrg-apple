//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// Extensions allowing the use of KVO to detect user default changes by key.
// See https://stackoverflow.com/a/47856467/760435
extension UserDefaults {
    @objc dynamic var PlaySRGSettingSelectedLiveStreamURNForChannels: [String: Any]? {
        return dictionary(forKey: PlaySRG.PlaySRGSettingSelectedLiveStreamURNForChannels)
    }
}
