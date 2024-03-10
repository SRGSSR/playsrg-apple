//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum SquareImages: String, CaseIterable, Identifiable {
    case `default`
    case forced
    case ignored
    
    var id: Self {
        return self
    }
    
    var description: String {
        switch self {
        case .forced:
            return NSLocalizedString("Force", comment: "Square images setting state")
        case .ignored:
            return NSLocalizedString("Ignore", comment: "Square images setting state")
        case .`default`:
            return NSLocalizedString("Default (current configuration)", comment: "Square images setting state")
        }
    }
}
