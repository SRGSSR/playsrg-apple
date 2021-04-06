//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private static func radioPlaySectionType(from homeSection: HomeSection, withChannelUid channelUid: String) -> PlaySection.`Type`? {
        switch homeSection {
        case .radioLatestEpisodes:
            return .radioLatestEpisodes(channelUid: channelUid)
        case .radioMostPopular:
            return .radioMostPopular(channelUid: channelUid)
        case .radioLatest:
            return .radioLatest(channelUid: channelUid)
        case .radioLatestVideos:
            return .radioLatestVideos(channelUid: channelUid)
        case .radioAllShows:
            return .radioAllShows(channelUid: channelUid)
        case .radioFavoriteShows:
            return .radioFavoriteShows(channelUid: channelUid)
        case .radioShowsAccess:
            return .radioShowAccess(channelUid: channelUid)
        default:
            return nil
        }
    }
    
    private static func contentPresentationType(from playSectionType: PlaySection.`Type`, index: Int) -> SRGContentPresentationType {
        switch playSectionType {
        case .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
            return index == 0 ? .hero : .swimlane
        case .radioAllShows:
            return .grid
        case .radioFavoriteShows:
            return .favoriteShows
        case .radioShowAccess:
            return .showAccess
        case .tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams:
            return .livestreams
        }
    }
    
    func playSections() -> [PlaySection] {
        var playSections = [PlaySection]()
        for (index, homeSection) in homeSections.enumerated() {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let playSectionType = Self.radioPlaySectionType(from: homeSection, withChannelUid: uid) {
                let contentPresentationType = Self.contentPresentationType(from: playSectionType, index: index)
                playSections.append(PlaySection(type: playSectionType, contentPresentationType: contentPresentationType))
            }
        }
        return playSections
    }
}
