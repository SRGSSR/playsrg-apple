//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// MARK: - View Model

final class FavoriteEpisodesViewModel: ObservableObject {
    @Published private(set) var medias: [SRGMedia] = []
    
    init() {
        SRGDataProvider.current!
            .latestMediasForShowsPublisher2(withUrns: FavoritesShowURNs().array as? [String] ?? [], pageSize: 12)
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$medias)
    }
}
