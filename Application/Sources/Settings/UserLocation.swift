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
        self
    }

    var description: String {
        switch self {
        case .WW:
            NSLocalizedString("Outside Switzerland", comment: "User location setting state")
        case .CH:
            NSLocalizedString("Ignore location", comment: "User location setting state")
        case .default:
            NSLocalizedString("Default (IP-based location)", comment: "User location setting state")
        }
    }
}
