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
        self
    }

    var description: String {
        switch self {
        case .curatedOne:
            NSLocalizedString("One curated page (PAC Audio)", comment: "One curated audio homepage option setting state")
        case .curatedMany:
            NSLocalizedString("Many curated pages (PAC landing pages)", comment: "Many curated audio homepages option setting state")
        case .predefinedMany:
            NSLocalizedString("Many predefined pages", comment: "Many predefined audio homepage option setting state")
        case .default:
            NSLocalizedString("Default (current configuration)", comment: "Audio homepage option setting state")
        }
    }
}
