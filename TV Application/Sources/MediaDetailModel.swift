//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class MediaDetailModel: ObservableObject {
    let media: SRGMedia
    
    @Published private(set) var relatedMedias: [SRGMedia] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init(media: SRGMedia) {
        self.media = media
    }
    
    func refresh() {
        guard let show = media.show else { return }
        SRGDataProvider.current!.latestMediasForShows(withUrns: [show.urn], filter: .episodesOnly)
            .map { $0.medias }
            .replaceError(with: [])
            .assign(to: \.relatedMedias, on: self)
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
}
