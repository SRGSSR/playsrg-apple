//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension SRGShow {
    @objc var play_contentType: ContentType {
        switch transmission {
        case .TV:
            .videoOrTV
        case .radio:
            .audioOrRadio
        default:
            .mixed
        }
    }

    var play_summary: String? {
        ApplicationConfiguration.shared.isShowLeadPreferred ? leadOrSummary : summaryOrLead
    }

    private var leadOrSummary: String? {
        lead?.isEmpty ?? true ? summary : lead
    }

    private var summaryOrLead: String? {
        summary?.isEmpty ?? true ? lead : summary
    }
}
