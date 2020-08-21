//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension RadioChannel {
    private func homeRowId(from homeSection: HomeSection, withChannelUid channelUid: String) -> HomeRow.Id? {
        switch homeSection {
            case .radioLatestEpisodes:
                return .radioLatestEpisodes(channelUid: channelUid)
            case .radioMostPopular:
                return .radioMostPopular(channelUid: channelUid)
            case .radioLatest:
                return .radioLatest(channelUid: channelUid)
            case .radioLatestVideos:
                return .radioLatestVideos(channelUid: channelUid)
            case .radioShowsAccess:
                return .radioShowsAccess(channelUid: channelUid)
            default:
                return nil
        }
    }
    
    func homeRowIds() -> [HomeRow.Id] {
        var rowIds = [HomeRow.Id]()
        for homeSection in homeSections {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let rowId = homeRowId(from: homeSection, withChannelUid: uid) {
                rowIds.append(rowId)
            }
        }
        return rowIds
    }
}
