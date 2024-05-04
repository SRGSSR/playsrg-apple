//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum AudioContentHomePageOption: String, CaseIterable, Identifiable {
    case `default`
    case forced
    case ignored
    
    var id: Self {
        return self
    }
    
    var description: String {
        switch self {
        case .forced:
            return NSLocalizedString("Force", comment: "Audio content home page option setting state")
        case .ignored:
            return NSLocalizedString("Ignore", comment: "Audio content home page option setting state")
        case .`default`:
            return NSLocalizedString("Default (current configuration)", comment: "Audio content home page option setting state")
        }
    }
}
