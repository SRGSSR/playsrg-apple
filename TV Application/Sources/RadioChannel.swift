//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private func homeRowId(from homeSection: HomeSection, withChannelUid channelUid: String) -> HomeRowId? {
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
        default:
            return nil
        }
    }
    
    func homeRowIds() -> [HomeRowId] {
        var rowIds = [HomeRowId]()
        for homeSection in homeSections {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let rowId = homeRowId(from: homeSection, withChannelUid: uid) {
                rowIds.append(rowId)
            }
        }
        return rowIds
    }
}
