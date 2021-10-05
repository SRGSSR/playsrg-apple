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
            return latestEpisodesFromFavoritesPublisher(with: interfaceController)
        case let .livestreams(contentProviders: contentProviders, action: action):
            return livestreamsPublisher(with: interfaceController, contentProviders: contentProviders, action: action)
        case let .mostPopularMedias(channelUid: channelUid):
            return mostPopularMediasPublisher(with: interfaceController, channelUid: channelUid)
        }
    }
    
    private static func logoImage(for media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return RadioChannelLogoImageWithTraitCollection(radioChannel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }
}

// MARK: Associated types

extension CarPlayList {
    private struct MediaData {
        let media: SRGMedia
        let image: UIImage?
    }
    
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
                
                let template = CarPlayListTemplate.template(list: .mostPopularMedias(channelUid: channelUid), interfaceController: interfaceController)
                interfaceController.pushTemplate(template, animated: true) { _, _ in
                    completion()
                }
            }
        }
    }
}

// MARK: Publishers

extension CarPlayList {
    private func latestEpisodesFromFavoritesPublisher(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        return SRGDataProvider.current!.latestMediasForShowsPublisher2(withUrns: FavoritesShowURNs().array as? [String] ?? [], pageSize: 12)
            .map { medias in
                return Publishers.AccumulateLatestMany(medias.map { media in
                    return self.mediaDataPublisher(for: media)
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
    
    private func livestreamsPublisher(with interfaceController: CPInterfaceController, contentProviders: SRGContentProviders, action: Action) -> AnyPublisher<[CPListSection], Error> {
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
    }
    
    private func mostPopularMediasPublisher(with interfaceController: CPInterfaceController, channelUid: String) -> AnyPublisher<[CPListSection], Error> {
        return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: channelUid)
            .map { medias in
                return Publishers.AccumulateLatestMany(medias.map { media in
                    return self.mediaDataPublisher(for: media)
                })
            }
            .switchToLatest()
            .map { mediaDataList in
                let items = mediaDataList.map { mediaData -> CPListItem in
                    let item = CPListItem(text: MediaDescription.title(for: mediaData.media, style: .show),
                                          detailText: MediaDescription.subtitle(for: mediaData.media, style: .show),
                                          image: mediaData.image)
                    item.accessoryType = .disclosureIndicator
                    item.handler = { _, completion in
                        interfaceController.play(media: mediaData.media, completion: completion)
                    }
                    return item
                }
                return [CPListSection(items: items)]
            }
            .eraseToAnyPublisher()
    }
    
    private func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
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
