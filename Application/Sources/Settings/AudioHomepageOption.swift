//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum AudioHomepageOption: String, CaseIterable, Identifiable {
    case `default`
    case curatedOne
    case curatedMany
    case predefinedMany
    
    var id: Self {
        return self
    }
    
    var useChannelContenId: Bool {
        return self == .curatedMany
    }
    
    var description: String {
        switch self {
        case .curatedOne:
            return NSLocalizedString("One curated page", comment: "One curated audio homepage option setting state")
        case .curatedMany:
            return NSLocalizedString("Many curated pages", comment: "Many curated audio homepages option setting state")
        case .predefinedMany:
            return NSLocalizedString("Many predefined pages", comment: "Many predefined audio homepage option setting state")
        case .`default`:
            return NSLocalizedString("Default (current configuration)", comment: "Audio homepage option setting state")
        }
    }
}
