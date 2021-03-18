//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private func homeRowId(from homeSection: HomeSection, withChannelUid channelUid: String) -> SRGContentSection? {
        switch homeSection {
        // TODO: Support remote config as SRGContentSection?
//        case .radioLatestEpisodes:
//            return .radioLatestEpisodes(channelUid: channelUid)
//        case .radioMostPopular:
//            return .radioMostPopular(channelUid: channelUid)
//        case .radioLatest:
//            return .radioLatest(channelUid: channelUid)
//        case .radioLatestVideos:
//            return .radioLatestVideos(channelUid: channelUid)
//        case .radioAllShows:
//            return .radioAllShows(channelUid: channelUid)
//        case .radioFavoriteShows:
//            return .radioFavoriteShows(channelUid: channelUid)
        default:
            return nil
        }
    }
    
    func homeRowIds() -> [SRGContentSection] {
        var rowIds = [SRGContentSection]()
        for homeSection in homeSections {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let rowId = homeRowId(from: homeSection, withChannelUid: uid) {
                rowIds.append(rowId)
            }
        }
        return rowIds
    }
}
