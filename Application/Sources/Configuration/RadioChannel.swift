//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private static func configuredSection(from homeSection: HomeSection, withChannelUid channelUid: String) -> ConfiguredSection? {
        switch homeSection {
        case .radioAllShows:
            .radioAllShows(channelUid: channelUid)
        case .radioFavoriteShows:
            .radioFavoriteShows(channelUid: channelUid)
        case .radioLatest:
            .radioLatest(channelUid: channelUid)
        case .radioLatestEpisodes:
            .radioLatestEpisodes(channelUid: channelUid)
        case .radioLatestEpisodesFromFavorites:
            .radioLatestEpisodesFromFavorites(channelUid: channelUid)
        case .radioLatestVideos:
            .radioLatestVideos(channelUid: channelUid)
        case .radioMostPopular:
            .radioMostPopular(channelUid: channelUid)
        case .radioResumePlayback:
            .radioResumePlayback(channelUid: channelUid)
        case .radioWatchLater:
            .radioWatchLater(channelUid: channelUid)
        #if os(iOS)
            case .radioShowsAccess:
                .radioShowAccess(channelUid: channelUid)
        #endif
        default:
            nil
        }
    }

    func configuredSections() -> [ConfiguredSection] {
        homeSections.compactMap { homeSection in
            guard let homeSection = HomeSection(rawValue: homeSection.intValue) else { return nil }
            return Self.configuredSection(from: homeSection, withChannelUid: uid)
        }
    }

    @objc func sectionTitle(sectionContext: ApplicationSection) -> String {
        if sectionContext == .showByDate, showType == .podcast {
            NSLocalizedString("Podcasts by date", comment: "Title of the section when we show podcasts by date")
        } else {
            TitleForApplicationSection(sectionContext)
        }
    }
}
