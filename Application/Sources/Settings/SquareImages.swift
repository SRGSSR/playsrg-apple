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
        self
    }

    var description: String {
        switch self {
        case .forced:
            NSLocalizedString("Force", comment: "Square images setting state")
        case .ignored:
            NSLocalizedString("Ignore", comment: "Square images setting state")
        case .default:
            NSLocalizedString("Default (current configuration)", comment: "Square images setting state")
        }
    }
}
