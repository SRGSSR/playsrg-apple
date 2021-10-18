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
    case mostPopularMedias(radioChannel: RadioChannel)
    
    var title: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            return NSLocalizedString("Favorites", comment: "Favorites screen title")
        case .livestreams:
            return NSLocalizedString("Livestreams", comment: "Livestreams screen title")
        case .mostPopular:
            return NSLocalizedString("Trends", comment: "Trends screen title")
        case let .mostPopularMedias(radioChannel: radioChannel):
            return radioChannel.name
        }
    }
    
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
        case let .mostPopularMedias(radioChannel):
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.carPlay.rawValue, radioChannel.name]
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
            return SRGDataProvider.current!.livestreamsSections(for: .all, interfaceController: interfaceController)
        case .mostPopular:
            return SRGDataProvider.current!.mostPopular(interfaceController: interfaceController)
        case let .mostPopularMedias(radioChannel: radioChannel):
            return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: radioChannel.uid)
                .mapToSections(with: interfaceController)
        }
    }
}

private extension CarPlayList {
    struct MediaData {
        let media: SRGMedia
        let image: UIImage
        let progress: Double?
    }
    
    static func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
        return Publishers.CombineLatest(
            imagePublisher(for: media),
            UserDataPublishers.playbackProgressPublisher(for: media)
        )
        .map { image, progress in
            return MediaData(media: media, image: image, progress: progress)
        }
        .eraseToAnyPublisher()
    }
    
    private static func imagePublisher(for media: SRGMedia) -> AnyPublisher<UIImage, Never> {
        let imageScale = ImageScale.small
        let placeholderImage = UIColor.placeholder.image(ofSize: SizeForImageScale(imageScale, .default))
        if let imageUrl = media.imageUrl(for: imageScale) {
            return ImagePipeline.shared.imagePublisher(with: imageUrl)
                .map { $0.image }
                .replaceError(with: placeholderImage)
                .prepend(placeholderImage)
                .eraseToAnyPublisher()
        }
        else {
            return Just(placeholderImage)
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

// MARK: Publishers

private extension SRGDataProvider {
    private static func logoImage(for media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return logoImage(for: radioChannel)
    }
    
    private static func logoImage(for channel: RadioChannel) -> UIImage? {
        return RadioChannelLogoImageWithTraitCollection(channel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }
    
    func livestreamsSections(for contentProviders: SRGContentProviders, interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        return radioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: contentProviders)
            .map { medias in
                let items = medias.map { media -> CPListItem in
                    let item = CPListItem(text: media.channel?.title, detailText: nil, image: Self.logoImage(for: media))
                    item.accessoryType = .none
                    item.handler = { _, completion in
                        interfaceController.play(media: media, completion: completion)
                    }
                    return item
                }
                return [CPListSection(items: items)]
            }
            .eraseToAnyPublisher()
    }
    
    func mostPopular(interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        let radioChannels = ApplicationConfiguration.shared.radioChannels
        if radioChannels.count == 1, let radioChannel = radioChannels.first {
            return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: radioChannel.uid)
                .mapToSections(with: interfaceController)
        }
        else {
            return radioChannels.publisher
                .map { radioChannel in
                    let item = CPListItem(text: radioChannel.name, detailText: nil, image: Self.logoImage(for: radioChannel))
                    item.accessoryType = .disclosureIndicator
                    item.handler = { _, completion in
                        let template = CPListTemplate(list: .mostPopularMedias(radioChannel: radioChannel), interfaceController: interfaceController)
                        interfaceController.pushTemplate(template, animated: true) { _, _ in
                            completion()
                        }
                    }
                    return item
                }
                .collect()
                .map { [CPListSection(items: $0)] }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
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
                item.playbackProgress = mediaMetadata.progress ?? 0
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
