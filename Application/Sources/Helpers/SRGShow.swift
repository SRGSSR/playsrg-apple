//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProvider

extension SRGShow {
    var leadOrSummary: String? {
        return lead?.isEmpty ?? true ? summary : lead
    }
}
