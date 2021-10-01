//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import Combine
import Nuke

// MARK: - View Model

final class FavoriteEpisodesViewModel: ObservableObject {
    @Published private(set) var medias: [MediaData] = []
    
    struct MediaData {
        let media: SRGMedia
        let image: UIImage?
    }
    
    init() {
        SRGDataProvider.current!
            .latestMediasForShowsPublisher2(withUrns: FavoritesShowURNs().array as? [String] ?? [], pageSize: 12) // Get favorites medias
            .map { medias in
                return Publishers.AccumulateLatestMany(medias.map({ media in // Accumulate publisher with medias and images
                    return self.mediaDataPublisher(for: media) // Build publisher <MediaData, Never>
                }))
            }
            .switchToLatest()
            .replaceError(with: []) // Replace error for latestMediasForShowsPublisher2
            .receive(on: DispatchQueue.main) // Receive in main queue
            .assign(to: &$medias) // Display medias
    }
    
    func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
        if let imageUrl = media.imageUrl(for: .small) { // Get image
            return ImagePipeline.shared.imagePublisher(with: imageUrl) // Use nuke to download image from url
                .map { MediaData(media: media, image: $0.image) } // Build MediaData(media, image)
                .replaceError(with: MediaData(media: media, image: UIImage(named: "media-background"))) // If error occurs build MediaData with placeholder
                .eraseToAnyPublisher()
        } else {
            return Just(MediaData(media: media, image: UIImage(named: "media-background")))
                .eraseToAnyPublisher()
        }
    }
}
