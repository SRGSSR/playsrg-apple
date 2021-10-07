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
    case livestreams
    case mostPopular
    case mostPopularMedias(channelUid: String)
    
    var title: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            return NSLocalizedString("Favorites", comment: "Favorites screen title")
        case .livestreams:
            return NSLocalizedString("Livestreams", comment: "Livestreams screen title")
        case .mostPopular:
            return NSLocalizedString("Trends", comment: "Trends screen title")
        case let .mostPopularMedias(channelUid: channelUid):
            if let channel = ApplicationConfiguration.shared.radioChannel(forUid: channelUid) {
                return channel.name
            }
            else {
                return nil
            }
        }
    }
    
    func publisher(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        switch self {
        case .latestEpisodesFromFavorites:
            return Publishers.PublishAndRepeat(onOutputFrom: UserInteractionSignal.favoriteUpdates()) {
                return SRGDataProvider.current!.favoritesPublisher(filter: self)
                    .map { SRGDataProvider.current!.latestMediasForShowsPublisher(withUrns: $0.map(\.urn)) }
                    .switchToLatest()
            }
            .mapToSections(with: interfaceController)
        case .livestreams:
            return SRGDataProvider.current!.livestreamsSections(for: .default, interfaceController: interfaceController, action: .play)
        case .mostPopular:
            return SRGDataProvider.current!.livestreamsSections(for: .all, interfaceController: interfaceController, action: .displayMostPopular)
        case let .mostPopularMedias(channelUid: channelUid):
            return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: channelUid)
                .mapToSections(with: interfaceController)
        }
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

// MARK: Protocols

extension CarPlayList: SectionFiltering {
    func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
        return shows.filter { $0.transmission == .radio }
    }
    
    func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
        return medias.filter { $0.mediaType == .audio }
    }
}

extension CarPlayList: CarPlayTracking {
    var pageViewTitle: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            return AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
        case .livestreams:
            return AnalyticsPageTitle.home.rawValue
        case .mostPopular, .mostPopularMedias:
            return AnalyticsPageTitle.mostPopular.rawValue
        }
    }
    
    var pageViewLevels: [String]? {
        switch self {
        case .latestEpisodesFromFavorites, .mostPopular:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.carPlay.rawValue]
        case .livestreams:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.carPlay.rawValue, AnalyticsPageLevel.live.rawValue]
        case let .mostPopularMedias(channelUid):
            if let channel = ApplicationConfiguration.shared.radioChannel(forUid: channelUid) {
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.carPlay.rawValue, channel.name]
            }
            else {
                return nil
            }
        }
    }
}

// MARK: Publishers

private extension SRGDataProvider {
    private static func logoImage(for media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return RadioChannelLogoImageWithTraitCollection(radioChannel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }
    
    func livestreamsSections(for contentProviders: SRGContentProviders, interfaceController: CPInterfaceController, action: CarPlayList.Action) -> AnyPublisher<[CPListSection], Error> {
        return radioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: contentProviders)
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
}

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
