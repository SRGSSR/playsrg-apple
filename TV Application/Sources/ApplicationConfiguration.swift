//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension ApplicationConfiguration {
    private func liveHomeRowId(from homeSection: HomeSection) -> SRGContentSection? {
        switch homeSection {
        // TODO: Support remote config as SRGContentSection?
//        case .tvLive:
//            return .tvLive
//        case .radioLive:
//            return .radioLive
//        case .radioLiveSatellite:
//            return .radioLiveSatellite
//        case .tvLiveCenter:
//            return .tvLiveCenter
//        case .tvScheduledLivestreams:
//            return .tvScheduledLivestreams
        default:
            return nil
        }
    }
    
    func liveHomeRowIds() -> [SRGContentSection] {
        var rowIds = [SRGContentSection]()
        for homeSection in liveHomeSections {
            if let homeSection = HomeSection(rawValue: homeSection.intValue),
               let rowId = liveHomeRowId(from: homeSection) {
                rowIds.append(rowId)
            }
        }
        return rowIds
    }
}
