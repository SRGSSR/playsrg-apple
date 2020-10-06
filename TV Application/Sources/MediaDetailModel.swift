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
        SRGDataProvider.current!.latestEpisodesForShow(withUrn: show.urn)
            .map { result -> [SRGMedia] in
                guard let episodes = result.episodeComposition.episodes else { return [] }
                var latestMedias = episodes.flatMap { episode -> [SRGMedia] in
                    guard let medias = episode.medias else { return [] }
                    return medias.filter { media in
                        return media.contentType == .episode || media.contentType == .scheduledLivestream
                    }
                }
                if !latestMedias.contains(self.media) {
                    latestMedias.append(self.media)
                }
                return latestMedias
            }
            .replaceError(with: [])
            .assign(to: \.relatedMedias, on: self)
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
}
