//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProvider

extension SRGMedia {
    var play_summary: String? {
        return leadOrSummary
    }
    
    private var leadOrSummary: String? {
        return lead?.isEmpty ?? true ? summary : lead
    }
}
