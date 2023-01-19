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
    
    var playAnalyticsClickEvent: AnalyticsClickEvent?
    var playAnalyticsClickEventMediaUrn: String?
    
    @Published private var mediaData: MediaData = .empty
    
    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        $media
            .dropFirst()
            .map { [weak self] media in
                guard let media else {
                    return Just(MediaData.empty).eraseToAnyPublisher()
                }
                return Publishers.CombineLatest(
                    UserDataPublishers.laterAllowedActionPublisher(for: media),
                    Self.relatedMediasPublisher(for: media, from: self?.mediaData ?? .empty)
                )
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
    
    var youthProtectionColor: SRGYouthProtectionColor? {
        let youthProtectionColor = media?.youthProtectionColor
        return youthProtectionColor != SRGYouthProtectionColor.none ? youthProtectionColor : nil
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
        guard let media else { return }
        WatchLaterToggleMedia(media) { added, error in
            guard error == nil else { return }
            
            let action = added ? .add : .remove as AnalyticsListAction
            AnalyticsHiddenEvent.watchLater(action: action, source: AnalyticsSource.button, urn: media.urn).send()
            
            self.mediaData = MediaData(media: media, watchLaterAllowedAction: added ? .remove : .add, relatedMedias: self.mediaData.relatedMedias)
        }
    }
}

// MARK: Publishers

extension MediaDetailViewModel {
    private static func relatedMediasPublisher(for media: SRGMedia?, from mediaData: MediaData) -> AnyPublisher<[SRGMedia], Never> {
        guard let media, media.contentType != .livestream, !mediaData.relatedMedias.contains(media) else {
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
            .prepend([])
            .eraseToAnyPublisher()
    }
}

// MARK: Types

extension MediaDetailViewModel {
    private struct MediaData {
        let media: SRGMedia?
        let watchLaterAllowedAction: WatchLaterAction
        let relatedMedias: [SRGMedia]
        
        static var empty = Self(media: nil, watchLaterAllowedAction: .none, relatedMedias: [])
    }
}
