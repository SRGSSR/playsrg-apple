//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum AudioHomepageOption: String, CaseIterable, Identifiable {
    case `default`
    case contentOne
    case contentMany
    case predefinedMany
    
    var id: Self {
        return self
    }
    
    var useChannelContenId: Bool {
        return self == .contentMany
    }
    
    var description: String {
        switch self {
        case .contentOne:
            return NSLocalizedString("One content page", comment: "One audio content home page option setting state")
        case .contentMany:
            return NSLocalizedString("Many content pages", comment: "Many audio content home pages option setting state")
        case .predefinedMany:
            return NSLocalizedString("Many predefined pages", comment: "Many predefined audio home page option setting state")
        case .`default`:
            return NSLocalizedString("Default (current configuration)", comment: "Audio content home page option setting state")
        }
    }
}
