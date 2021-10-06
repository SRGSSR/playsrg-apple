//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import SRGDataProviderCombine
import Nuke

// MARK: Types

enum CarPlayList {
    case latestEpisodesFromFavorites
    case livestreams(contentProviders: SRGContentProviders, action: Action)
    case mostPopularMedias(channelUid: String)
    
    var title: String {
        switch self {
        case .latestEpisodesFromFavorites:
            return NSLocalizedString("Favorites", comment: "Favorites screen title")
        case .livestreams:
            return NSLocalizedString("Livestreams", comment: "Livestreams screen title")
        case .mostPopularMedias:
            return NSLocalizedString("Trends", comment: "Trends screen title")
        }
    }
    
    func publisher(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        switch self {
        case .latestEpisodesFromFavorites:
            return Publishers.PublishAndRepeat(onOutputFrom: UserInteractionSignal.favoriteUpdates()) {
                return SRGDataProvider.current!.latestMediasForShowsPublisher2(withUrns: FavoritesShowURNs().array as? [String] ?? [], pageSize: 12)
            }
            .mapToSections(with: interfaceController)
        case let .livestreams(contentProviders: contentProviders, action: action):
            return SRGDataProvider.current!.radioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: contentProviders)
                .map { medias in
                    let items = medias.map { media -> CPListItem in
                        let item = CPListItem(text: media.channel?.title, detailText: nil, image: Self.logoImage(for: media))
                        item.accessoryType = .disclosureIndicator
                        item.handler = { _, completion in
                            action.perform(for: media, interfaceController: interfaceController, completion: completion)
                        }
                        return item
                    }
                    return [CPListSection(items: items)]
                }
                .eraseToAnyPublisher()
        case let .mostPopularMedias(channelUid: channelUid):
            return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: channelUid)
                .mapToSections(with: interfaceController)
        }
    }
    
    private static func logoImage(for media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return RadioChannelLogoImageWithTraitCollection(radioChannel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }
}

extension CarPlayList {
    enum Action {
        case play
        case displayMostPopular
        
        fileprivate func perform(for media: SRGMedia, interfaceController: CPInterfaceController, completion: @escaping () -> Void) {
            switch self {
            case .play:
                interfaceController.play(media: media, completion: completion)
            case .displayMostPopular:
                guard let channelUid = media.channel?.uid else {
                    completion()
                    return
                }
                
                let template = CPListTemplate(list: .mostPopularMedias(channelUid: channelUid), interfaceController: interfaceController)
                interfaceController.pushTemplate(template, animated: true) { _, _ in
                    completion()
                }
            }
        }
    }
}

private extension CarPlayList {
    struct MediaData {
        let media: SRGMedia
        let image: UIImage?
    }
    
    static func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
        if let imageUrl = media.imageUrl(for: .small) {
            return ImagePipeline.shared.imagePublisher(with: imageUrl)
                .map { Optional($0.image) }
                .replaceError(with: UIImage(named: "media-background"))
                .map { MediaData(media: media, image: $0) }
                .eraseToAnyPublisher()
        }
        else {
            return Just(MediaData(media: media, image: UIImage(named: "media-background")))
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Publishers

private extension Publisher where Output == [SRGMedia] {
    func mapToSections(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Failure> {
        return map { medias in
            return Publishers.AccumulateLatestMany(medias.map { media in
                return CarPlayList.mediaDataPublisher(for: media)
            })
        }
        .switchToLatest()
        .map { mediaMetadataList in
            let items = mediaMetadataList.map { mediaMetadata -> CPListItem in
                let item = CPListItem(text: MediaDescription.title(for: mediaMetadata.media, style: .show),
                                      detailText: MediaDescription.subtitle(for: mediaMetadata.media, style: .show),
                                      image: mediaMetadata.image)
                item.accessoryType = .disclosureIndicator
                item.handler = { _, completion in
                    interfaceController.play(media: mediaMetadata.media, completion: completion)
                }
                return item
            }
            return [CPListSection(items: items)]
        }
        .eraseToAnyPublisher()
    }
}
