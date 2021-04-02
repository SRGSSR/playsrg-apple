//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private func homePlaySection(from homeSection: HomeSection, withChannelUid channelUid: String) -> PlaySection? {
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
    
    func homePlaySections() -> [PlaySection] {
        var playSections = [PlaySection]()
        for homeSection in homeSections {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let playSection = homePlaySection(from: homeSection, withChannelUid: uid) {
                playSections.append(playSection)
            }
        }
        return playSections
    }
}
