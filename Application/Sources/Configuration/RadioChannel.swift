//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private static func configuredSectionType(from homeSection: HomeSection, withChannelUid channelUid: String) -> ConfiguredSection.`Type`? {
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
    
    private static func contentPresentationType(from configuredSectionType: ConfiguredSection.`Type`, index: Int) -> SRGContentPresentationType {
        switch configuredSectionType {
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
    
    func configuredSections() -> [ConfiguredSection] {
        var configuredSections = [ConfiguredSection]()
        for (index, homeSection) in homeSections.enumerated() {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let configuredSectionType = Self.configuredSectionType(from: homeSection, withChannelUid: uid) {
                let contentPresentationType = Self.contentPresentationType(from: configuredSectionType, index: index)
                configuredSections.append(ConfiguredSection(type: configuredSectionType, contentPresentationType: contentPresentationType))
            }
        }
        return configuredSections
    }
}