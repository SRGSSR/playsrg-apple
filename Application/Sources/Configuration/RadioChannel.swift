//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private static func configuredSection(from homeSection: HomeSection, withChannelUid channelUid: String) -> ConfiguredSection? {
        switch homeSection {
        case .radioAllShows:
            return .radioAllShows(channelUid: channelUid)
        case .radioFavoriteShows:
            return .radioFavoriteShows(channelUid: channelUid)
        case .radioLatest:
            return .radioLatest(channelUid: channelUid)
        case .radioLatestEpisodes:
            return .radioLatestEpisodes(channelUid: channelUid)
        case .radioLatestEpisodesFromFavorites:
            return .radioLatestEpisodesFromFavorites(channelUid: channelUid)
        case .radioLatestVideos:
            return .radioLatestVideos(channelUid: channelUid)
        case .radioMostPopular:
            return .radioMostPopular(channelUid: channelUid)
        case .radioResumePlayback:
            return .radioResumePlayback(channelUid: channelUid)
        case .radioWatchLater:
            return .radioWatchLater(channelUid: channelUid)
        #if os(iOS)
            case .radioShowsAccess:
                return .radioShowAccess(channelUid: channelUid)
        #endif
        default:
            return nil
        }
    }

    func configuredSections() -> [ConfiguredSection] {
        return homeSections.compactMap { homeSection in
            guard let homeSection = HomeSection(rawValue: homeSection.intValue) else { return nil }
            return Self.configuredSection(from: homeSection, withChannelUid: uid)
        }
    }
}
