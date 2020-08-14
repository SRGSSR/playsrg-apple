//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

struct ApplicationConfiguration {
    static let vendor: SRGVendor = .RTS
    static let pageSize: UInt = 20
    static let tvTrendingEditorialLimit: UInt = 3
    static let tvTrendingEpisodesOnly: Bool = false
    
    static let rowIds: [HomeRow.Id] = [
        .trending(appearance: .hero),
        .topics,
        .latestForModule(nil, type: .event),
        .latestForTopic(nil),
        .latest,
        .mostPopular,
        .soonExpiring
    ]
}
