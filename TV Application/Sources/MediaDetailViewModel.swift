//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

// MARK: View model

final class MediaDetailViewModel: ObservableObject {
    @Published var media: SRGMedia?
    
    @Published private var mediaData: MediaData = .empty
    
    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        $media
            .dropFirst()
            .map { media -> AnyPublisher<MediaData, Never> in
                guard let media = media else {
                    return Just(MediaData.empty).eraseToAnyPublisher()
                }
                return Publishers.CombineLatest(UserDataPublishers.laterAllowedActionPublisher(for: media),
                                                Self.relatedMediasPublisher(for: media, from: self.mediaData))
                .map { action, relatedMedias in
                    return MediaData(media: media, watchLaterAllowedAction: action, relatedMedias: relatedMedias)
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$mediaData)
    }
    
    var showTitle: String? {
        if let showTitle = media?.show?.title, showTitle.lowercased() != media?.title.lowercased() {
            return showTitle
        }
        else {
            return nil
        }
    }
    
    var imageUrl: URL? {
        return url(for: media?.image, size: .large)
    }
    
    var watchLaterAllowedAction: WatchLaterAction {
        return mediaData.watchLaterAllowedAction
    }
    
    var relatedMedias: [SRGMedia] {
        return mediaData.relatedMedias
    }
    
    func toggleWatchLater() {
        guard let media = media else { return }
        WatchLaterToggleMedia(media) { added, error in
            guard error == nil else { return }
            
            let analyticsTitle = added ? AnalyticsTitle.watchLaterAdd : AnalyticsTitle.watchLaterRemove
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.button.rawValue
            labels.value = media.urn
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: analyticsTitle.rawValue, labels: labels)
            
            self.mediaData = MediaData(media: media, watchLaterAllowedAction: added ? .remove : .add, relatedMedias: self.mediaData.relatedMedias)
        }
    }
}

// MARK: Publishers

extension MediaDetailViewModel {
    private static func relatedMediasPublisher(for media: SRGMedia?, from mediaData: MediaData) -> AnyPublisher<[SRGMedia], Never> {
        guard let media = media, media.contentType != .livestream, !mediaData.relatedMedias.contains(media) else {
            return Just(mediaData.relatedMedias).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: ApplicationConfiguration.shared.relatedContentUrl(for: media))
            .map(\.data)
            .decode(type: Recommendation.self, decoder: JSONDecoder())
            .map { recommendation in
                return SRGDataProvider.current!.medias(withUrns: recommendation.urns)
            }
            .switchToLatest()
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
}

// MARK: Types

extension MediaDetailViewModel {
    private struct MediaData {
        let media: SRGMedia?
        let watchLaterAllowedAction: WatchLaterAction
        let relatedMedias: [SRGMedia]
        
        static var empty = MediaData(media: nil, watchLaterAllowedAction: .none, relatedMedias: [])
    }
}
