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
    case livestream(channel: SRGChannel, media: SRGMedia)
    
    private static let pageSize: UInt = 20
    
    var title: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            return NSLocalizedString("Favorites", comment: "Tab title to present the latest episodes from favorite shows on CarPlay")
        case .livestreams:
            return NSLocalizedString("Livestreams", comment: "Tab title to present the livestreams on CarPlay")
        case .mostPopular:
            return NSLocalizedString("Trends", comment: "Tab title to present the most popular medias by channel on CarPlay")
        case let .mostPopularMedias(radioChannel: radioChannel):
            return radioChannel.name
        case let .livestream(channel: channel, _):
            return channel.title
        }
    }
    
    var pageViewTitle: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            return AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
        case .livestreams, .mostPopular:
            return AnalyticsPageTitle.home.rawValue
        case .mostPopularMedias:
            return AnalyticsPageTitle.mostPopular.rawValue
        case .livestream:
            return AnalyticsPageTitle.livestream.rawValue
        }
    }
    
    var pageViewLevels: [String]? {
        switch self {
        case .latestEpisodesFromFavorites:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        case .livestreams:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, AnalyticsPageLevel.live.rawValue]
        case .mostPopular:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, AnalyticsPageLevel.mostPopular.rawValue]
        case let .mostPopularMedias(radioChannel):
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, radioChannel.name]
        case let .livestream(channel, _):
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, channel.title]
        }
    }
    
    func publisher(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        switch self {
        case .latestEpisodesFromFavorites:
            return Publishers.PublishAndRepeat(onOutputFrom: UserInteractionSignal.favoriteUpdates()) {
                return SRGDataProvider.current!.favoritesPublisher(filter: self)
                    .map { SRGDataProvider.current!.latestMediasForShowsPublisher(withUrns: $0.map(\.urn), pageSize: Self.pageSize) }
                    .switchToLatest()
            }
            .mapToSections(with: interfaceController)
        case .livestreams:
            return Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.settingUpdates(at: \.PlaySRGSettingSelectedLivestreamURNForChannels)) {
                return Self.livestreamsSections(for: .all, interfaceController: interfaceController)
            }
        case .mostPopular:
            return Self.mostPopular(interfaceController: interfaceController)
        case let .mostPopularMedias(radioChannel: radioChannel):
            return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: radioChannel.uid, pageSize: Self.pageSize)
                .mapToSections(with: interfaceController)
        case let .livestream(_, media: media):
            return Self.livestreamSections(for: media, interfaceController: interfaceController)
        }
    }
}

private extension CarPlayList {
    struct LiveMediaData {
        let media: SRGMedia
        let programMedias: [SRGMedia]
        let playing: Bool
    }
    
    struct MediaData {
        let media: SRGMedia
        let image: UIImage
        let playing: Bool
        let progress: Double?
    }
    
    static func liveMediaDataPublisher(for media: SRGMedia) -> AnyPublisher<LiveMediaData, Never> {
        return Publishers.CombineLatest(
            playingPublisher(for: media),
            liveProgramMediasPublisher(for: media)
        )
        .map { playing, liveProgramMedias in
            return LiveMediaData(media: media, programMedias: liveProgramMedias, playing: playing)
        }
        .eraseToAnyPublisher()
    }
    
    static func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
        return Publishers.CombineLatest3(
            imagePublisher(for: media),
            playingPublisher(for: media),
            UserDataPublishers.playbackProgressPublisher(for: media)
        )
        .map { image, playing, progress in
            return MediaData(media: media, image: image, playing: playing, progress: progress)
        }
        .eraseToAnyPublisher()
    }
    
    private static func playingPublisher(for media: SRGMedia) -> AnyPublisher<Bool, Never> {
        return nowPlayingMediaPublisher()
            .map { media == $0 }
            .eraseToAnyPublisher()
    }
    
    private static func imagePublisher(for media: SRGMedia) -> AnyPublisher<UIImage, Never> {
        let imageSize = SRGImageSize.small
        let placeholderImage = UIColor.placeholder.image(ofSize: SRGRecommendedImageCGSize(imageSize, .default))
        if let imageUrl = url(for: media.image, size: imageSize) {
            return ImagePipeline.shared.imagePublisher(with: imageUrl)
                .map(\.image)
                .replaceError(with: placeholderImage)
                .prepend(placeholderImage)
                .eraseToAnyPublisher()
        }
        else {
            return Just(placeholderImage)
                .eraseToAnyPublisher()
        }
    }
    
    private static func nowPlayingMedia(for controller: SRGLetterboxController?) -> SRGMedia? {
        guard let controller = controller else { return nil }
        if let fullLengthMedia = controller.fullLengthMedia, fullLengthMedia.contentType == .livestream || fullLengthMedia.contentType == .scheduledLivestream {
            return fullLengthMedia
        }
        else {
            return controller.media
        }
    }
    
    private static func nowPlayingMediaPublisher() -> AnyPublisher<SRGMedia?, Never> {
        return SRGLetterboxService.shared.publisher(for: \.controller)
            .map { controller -> AnyPublisher<SRGMedia?, Never> in
                if let controller = controller {
                    return NotificationCenter.default.weakPublisher(for: NSNotification.Name.SRGLetterboxMetadataDidChange, object: controller)
                        .map { notification in
                            let controller = notification.object as? SRGLetterboxController
                            return nowPlayingMedia(for: controller)
                        }
                        .prepend(nowPlayingMedia(for: controller))
                        .eraseToAnyPublisher()
                }
                else {
                    return Just(nil)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private static func liveProgramMediasPublisher(for media: SRGMedia) -> AnyPublisher<[SRGMedia], Never> {
        return SRGDataProvider.current!.mediaComposition(forUrn: media.urn)
            .map { mediaComposition in
                let segments = mediaComposition.mainChapter.segments ?? []
                let now = Date()
                
                return segments
                    .reversed()
                    .filter({
                        guard let markInDate = $0.markInDate else { return false }
                        return markInDate <= now
                    })
                    .map({ mediaComposition.media(for: $0)! })
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()
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

private extension CarPlayList {
    private static func logoImage(for media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return logoImage(for: radioChannel)
    }
    
    private static func logoImage(for channel: RadioChannel) -> UIImage? {
        return RadioChannelLogoImageWithTraitCollection(channel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }
    
    static func livestreamsSections(for contentProviders: SRGContentProviders, interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        return SRGDataProvider.current!.regionalizedRadioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: contentProviders)
            .map { medias in
                return Publishers.AccumulateLatestMany(medias.map { media in
                    return liveMediaDataPublisher(for: media)
                })
            }
            .switchToLatest()
            .map { liveMediaDataList in
                let items = liveMediaDataList.map { liveMediaData -> CPListItem in
                    if liveMediaData.programMedias.isEmpty {
                        let item = CPListItem(text: liveMediaData.media.channel?.title, detailText: NSLocalizedString("Livestream", comment: "Subtitle label to present the livestream media only"), image: Self.logoImage(for: liveMediaData.media))
                        item.accessoryType = .none
                        item.handler = { _, completion in
                            interfaceController.play(media: liveMediaData.media, completion: completion)
                        }
                        item.isPlaying = liveMediaData.playing
                        return item
                    }
                    else {
                        let item = CPListItem(text: liveMediaData.media.channel?.title, detailText: NSLocalizedString("Livestream and latest programs", comment: "Subtitle label to present the livestream media and its latest programs"), image: Self.logoImage(for: liveMediaData.media))
                        item.accessoryType = .disclosureIndicator
                        item.handler = { _, completion in
                            let template = CPListTemplate.list(.livestream(channel: liveMediaData.media.channel!, media: liveMediaData.media), interfaceController: interfaceController)
                            interfaceController.pushTemplate(template, animated: true) { _, _ in
                                completion()
                            }
                        }
                        item.isPlaying = liveMediaData.playing
                        return item
                    }
                }
                return [CPListSection(items: items)]
            }
            .eraseToAnyPublisher()
    }
    
    static func mostPopular(interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        let radioChannels = ApplicationConfiguration.shared.radioHomepageChannels
        if radioChannels.count == 1, let radioChannel = radioChannels.first {
            return SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: radioChannel.uid)
                .mapToSections(with: interfaceController)
        }
        else {
            return radioChannels.publisher
                .map { radioChannel in
                    let item = CPListItem(text: radioChannel.name, detailText: nil, image: logoImage(for: radioChannel))
                    item.accessoryType = .disclosureIndicator
                    item.handler = { _, completion in
                        let template = CPListTemplate.list(.mostPopularMedias(radioChannel: radioChannel), interfaceController: interfaceController)
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
    
    static func livestreamSections(for media: SRGMedia, interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        return liveProgramMediasPublisher(for: media)
            .map { [media] + $0 }
            .setFailureType(to: Error.self)
            .mapToSections(with: interfaceController, style: .time)
    }
}

private extension Publisher where Output == [SRGMedia] {
    func mapToSections(with interfaceController: CPInterfaceController, style: MediaDescription.Style = .show) -> AnyPublisher<[CPListSection], Failure> {
        return map { medias in
            return Publishers.AccumulateLatestMany(medias.map { media in
                return CarPlayList.mediaDataPublisher(for: media)
            })
        }
        .switchToLatest()
        .map { mediaDataList in
            let items = mediaDataList.map { mediaData -> CPListItem in
                let item = CPListItem(text: MediaDescription.title(for: mediaData.media, style: style),
                                      detailText: MediaDescription.subtitle(for: mediaData.media, style: style),
                                      image: mediaData.image)
                item.isPlaying = mediaData.playing
                item.playbackProgress = mediaData.progress ?? 0
                item.accessoryType = .none
                item.handler = { _, completion in
                    interfaceController.play(media: mediaData.media, completion: completion)
                }
                return item
            }
            return [CPListSection(items: items)]
        }
        .eraseToAnyPublisher()
    }
}
