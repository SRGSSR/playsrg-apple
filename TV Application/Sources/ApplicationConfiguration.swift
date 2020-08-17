//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

struct ApplicationConfiguration {
    static let vendor: SRGVendor = .RTS
    static let pageSize: UInt = 10
    static let tvTrendingEditorialLimit: UInt = 3
    static let tvTrendingEpisodesOnly: Bool = false
    
    static let tvHomeRowIds: [HomeRow.Id] = [
        .tvTrending(appearance: .hero),
        .tvTopics,
        .tvLatestForModule(nil, type: .event),
        .tvLatestForTopic(nil),
        .tvLatest,
        .tvMostPopular,
        .tvSoonExpiring
    ]
    
    static func radioHomeRowIds(for channelUid: String) -> [HomeRow.Id] {
        return [
            .radioLatestEpisodes(channelUid: channelUid),
            .radioMostPopular(channelUid: channelUid),
            .radioLatest(channelUid: channelUid),
            .radioLatestVideos(channelUid: channelUid)
        ]
    }
    
    static let liveHomeRowIds: [HomeRow.Id] = [
        .tvLive,
        .radioLive,
        .radioLiveSatellite,
        .liveCenter,
        .tvScheduledLivestreams
    ]
}
