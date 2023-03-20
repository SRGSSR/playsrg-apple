//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProvider

extension SRGShow {
    var play_summary: String? {
        return ApplicationConfiguration.shared.isShowLeadPreferred ? leadOrSummary : summaryOrLead
    }
    
    private var leadOrSummary: String? {
        return lead?.isEmpty ?? true ? summary : lead
    }
    
    private var summaryOrLead: String? {
        return summary?.isEmpty ?? true ? lead : summary
    }
}
