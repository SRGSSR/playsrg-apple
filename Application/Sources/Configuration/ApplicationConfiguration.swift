//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension ApplicationConfiguration {
    private static func configuredSectionType(from homeSection: HomeSection) -> ConfiguredSection.`Type`? {
        switch homeSection {
        case .tvLive:
            return .tvLive
        case .radioLive:
            return .radioLive
        case .radioLiveSatellite:
            return .radioLiveSatellite
        case .tvLiveCenter:
            return .tvLiveCenter
        case .tvScheduledLivestreams:
            return .tvScheduledLivestreams
        default:
            return nil
        }
    }
    
    private static func contentPresentationType(from homeSection: HomeSection) -> SRGContentPresentationType {
        switch homeSection {
        case .tvLive, .radioLive, .radioLiveSatellite:
            return .livestreams
        default:
            return .swimlane
        }
    }
    
    func liveConfiguredSections() -> [ConfiguredSection] {
        var configuredSections = [ConfiguredSection]()
        for homeSection in liveHomeSections {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let configuratedSectionType = Self.configuredSectionType(from: homeSection) {
                let contentPresentationType = Self.contentPresentationType(from: homeSection)
                configuredSections.append(ConfiguredSection(type: configuratedSectionType, contentPresentationType: contentPresentationType))
            }
        }
        return configuredSections
    }
}

struct ConfiguredSection: Hashable {
    enum `Type`: Hashable {
        case tvEpisodesForDay(_ day: SRGDay)
        
        case radioAllShows(channelUid: String)
        case radioEpisodesForDay(_ day: SRGDay, channelUid: String)
        case radioFavoriteShows(channelUid: String)
        case radioLatest(channelUid: String)
        case radioLatestEpisodes(channelUid: String)
        case radioLatestEpisodesFromFavorites(channelUid: String)
        case radioLatestVideos(channelUid: String)
        case radioMostPopular(channelUid: String)
        case radioResumePlayback(channelUid: String)
        case radioShowAccess(channelUid: String)
        case radioWatchLater(channelUid: String)
        
        case tvLive
        case radioLive
        case radioLiveSatellite
        
        case tvLiveCenter
        case tvScheduledLivestreams
    }
    
    let type: Type
    let contentPresentationType: SRGContentPresentationType
}
