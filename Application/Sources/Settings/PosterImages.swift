//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum PosterImages: String, CaseIterable, Identifiable {
    case `default`
    case forced
    case ignored
    
    var id: Self {
        return self
    }
    
    var description: String {
        switch self {
        case .forced:
            return NSLocalizedString("Force", comment: "Poster images setting state")
        case .ignored:
            return NSLocalizedString("Ignore", comment: "Poster images setting state")
        case .`default`:
            return NSLocalizedString("Default (current configuration)", comment: "Poster images setting state")
        }
    }
}
