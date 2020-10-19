//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

extension String {
    var capitalizedFirstLetter: String {
        return prefix(1).capitalized + dropFirst()
    }
}
