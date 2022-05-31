//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum UserLocation: String, CaseIterable, Identifiable {
    case `default` = ""
    case WW
    case CH
    
    var id: Self {
        return self
    }
    
    var description: String {
        switch self {
        case .WW:
            return PlaySRGSettingsLocalizedString("Outside Switzerland", comment: "User location setting state")
        case .CH:
            return PlaySRGSettingsLocalizedString("Ignore location", comment: "User location setting state")
        case .`default`:
            return PlaySRGSettingsLocalizedString("Default (IP-based location)", comment: "User location setting state")
        }
    }
}
