//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import Nuke
import SRGDataProviderCombine

// MARK: Types

enum CarPlayList {
    case latestEpisodesFromFavorites
    case livestreams
    case mostPopular
    case mostPopularMedias(radioChannel: RadioChannel)
    case livePrograms(channel: SRGChannel, media: SRGMedia)

    private static let pageSize: UInt = 20

    var title: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            NSLocalizedString("Favorites", comment: "Tab title to present the latest episodes from favorite shows on CarPlay")
        case .livestreams:
            NSLocalizedString("Livestreams", comment: "Tab title to present the livestreams on CarPlay")
        case .mostPopular:
            NSLocalizedString("Trends", comment: "Tab title to present the most popular medias by channel on CarPlay")
        case let .mostPopularMedias(radioChannel: radioChannel):
            radioChannel.name
        case .livePrograms:
            NSLocalizedString("Previous shows", comment: "Livestream previous programs screen title")
        }
    }

    var pageViewTitle: String? {
        switch self {
        case .latestEpisodesFromFavorites:
            AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
        case .livestreams, .mostPopular:
            AnalyticsPageTitle.home.rawValue
        case .mostPopularMedias:
            AnalyticsPageTitle.mostPopular.rawValue
        case .livePrograms:
            AnalyticsPageTitle.livePrograms.rawValue
        }
    }

    var pageViewType: String? {
        switch self {
        case .latestEpisodesFromFavorites, .livePrograms, .mostPopularMedias:
            AnalyticsPageType.detail.rawValue
        case .livestreams:
            AnalyticsPageType.live.rawValue
        case .mostPopular:
            AnalyticsPageType.overview.rawValue
        }
    }

    var pageViewLevels: [String]? {
        switch self {
        case .latestEpisodesFromFavorites:
            [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        case .livestreams:
            [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, AnalyticsPageLevel.live.rawValue]
        case .mostPopular:
            [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, AnalyticsPageLevel.mostPopular.rawValue]
        case let .mostPopularMedias(radioChannel):
            [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, radioChannel.name]
        case let .livePrograms(channel, _):
            [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue, channel.title]
        }
    }

    func publisher(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        switch self {
        case .latestEpisodesFromFavorites:
            Publishers.PublishAndRepeat(onOutputFrom: UserInteractionSignal.favoriteUpdates()) {
                SRGDataProvider.current!.favoritesPublisher(filter: self)
                    .map { SRGDataProvider.current!.latestMediasForShowsPublisher(withUrns: $0.map(\.urn), pageSize: Self.pageSize) }
                    .switchToLatest()
            }
            .mapToSections(with: interfaceController)
        case .livestreams:
            Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.settingUpdates(at: \.PlaySRGSettingSelectedLivestreamURNForChannels)) {
                Self.livestreamsSections(for: .all, interfaceController: interfaceController)
            }
        case .mostPopular:
            Self.mostPopular(interfaceController: interfaceController)
        case let .mostPopularMedias(radioChannel: radioChannel):
            SRGDataProvider.current!.radioMostPopularMedias(for: ApplicationConfiguration.shared.vendor, channelUid: radioChannel.uid, pageSize: Self.pageSize)
                .mapToSections(with: interfaceController)
        case let .livePrograms(channel, media):
            Publishers.PublishAndRepeat(onOutputFrom: Timer.publish(every: 30, on: .main, in: .common).autoconnect()) {
                Self.liveProgramsSections(for: channel, media: media, interfaceController: interfaceController)
            }
        }
    }
}

private extension CarPlayList {
    struct LiveMediaData {
        let media: SRGMedia
        let playing: Bool
    }

    struct LiveProgramData {
        let program: SRGProgram
        let image: UIImage
        let playing: Bool
    }

    struct MediaData {
        let media: SRGMedia
        let image: UIImage
        let playing: Bool
        let progress: Double?
    }

    static func liveMediaDataPublisher(for media: SRGMedia) -> AnyPublisher<LiveMediaData, Never> {
        playingPublisher(for: media.urn)
            .map { playing in
                LiveMediaData(media: media, playing: playing)
            }
            .eraseToAnyPublisher()
    }

    static func liveProgramDataPublisher(for program: SRGProgram) -> AnyPublisher<LiveProgramData, Never> {
        Publishers.CombineLatest(
            imagePublisher(for: program),
            playingPublisher(for: program.mediaURN)
        )
        .map { image, playing in
            LiveProgramData(program: program, image: image, playing: playing)
        }
        .eraseToAnyPublisher()
    }

    static func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
        Publishers.CombineLatest3(
            imagePublisher(for: media),
            playingPublisher(for: media.urn),
            UserDataPublishers.playbackProgressPublisher(for: media)
        )
        .map { image, playing, progress in
            MediaData(media: media, image: image, playing: playing, progress: progress)
        }
        .eraseToAnyPublisher()
    }

    private static func playingPublisher(for mediaUrn: String?) -> AnyPublisher<Bool, Never> {
        if let mediaUrn {
            nowPlayingMediaPublisher()
                .map { $0.map(\.urn).contains(mediaUrn) }
                .eraseToAnyPublisher()
        } else {
            Just(false)
                .eraseToAnyPublisher()
        }
    }

    private static func imagePublisher(for media: SRGMedia) -> AnyPublisher<UIImage, Never> {
        imagePublisher(for: media.image)
    }

    private static func imagePublisher(for program: SRGProgram) -> AnyPublisher<UIImage, Never> {
        imagePublisher(for: program.image)
    }

    private static func imagePublisher(for image: SRGImage?) -> AnyPublisher<UIImage, Never> {
        let imageSize = SRGImageSize.small
        let placeholderImage = UIColor.placeholder.image(ofSize: SRGRecommendedImageCGSize(imageSize, .default))
        if let imageUrl = url(for: image, size: imageSize) {
            return ImagePipeline.shared.imagePublisher(with: imageUrl)
                .map(\.image)
                .replaceError(with: placeholderImage)
                .prepend(placeholderImage)
                .eraseToAnyPublisher()
        } else {
            return Just(placeholderImage)
                .eraseToAnyPublisher()
        }
    }

    private static func nowPlayingMedia(for controller: SRGLetterboxController?) -> [SRGMedia] {
        guard let controller else { return [] }

        var medias: Set<SRGMedia> = []
        if let mainMedia = controller.play_mainMedia {
            medias.insert(mainMedia)
        }
        if let media = controller.media {
            medias.insert(media)
        }
        return Array(medias)
    }

    private static func nowPlayingMediaPublisher() -> AnyPublisher<[SRGMedia], Never> {
        SRGLetterboxService.shared.publisher(for: \.controller)
            .map { controller -> AnyPublisher<[SRGMedia], Never> in
                if let controller {
                    NotificationCenter.default.weakPublisher(for: .SRGLetterboxMetadataDidChange, object: controller)
                        .map { notification in
                            let controller = notification.object as? SRGLetterboxController
                            return nowPlayingMedia(for: controller)
                        }
                        .prepend(nowPlayingMedia(for: controller))
                        .eraseToAnyPublisher()
                } else {
                    Just([])
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private static func liveProgramsPublisher(for channel: SRGChannel, media: SRGMedia) -> AnyPublisher<[SRGProgram], Error> {
        if let controller = SRGLetterboxService.shared.controller,
           let dateInterval = controller.play_dateInterval,
           let segments = controller.mediaComposition?.mainChapter.segments, !segments.isEmpty {
            SRGDataProvider.current!.radioLatestPrograms(for: ApplicationConfiguration.shared.vendor,
                                                         channelUid: channel.uid,
                                                         livestreamUid: media.uid,
                                                         from: nil, to: nil,
                                                         pageSize: 50, paginatedBy: nil)
                .map { _, programs in
                    programs
                        .filter { $0.startDate >= dateInterval.start && $0.startDate <= dateInterval.end }
                        .reversed()
                }
                .eraseToAnyPublisher()
        } else {
            Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Protocols

extension CarPlayList: SectionFiltering {
    func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
        shows.filter { $0.transmission == .radio }
    }

    func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
        medias.filter { $0.mediaType == .audio }
    }
}

// MARK: Publishers

private extension CarPlayList {
    private static func logoImage(for media: SRGMedia) -> UIImage? {
        guard let channel = media.channel, let radioChannel = ApplicationConfiguration.shared.radioChannel(forUid: channel.uid) else { return nil }
        return logoImage(for: radioChannel)
    }

    private static func logoImage(for channel: RadioChannel) -> UIImage? {
        RadioChannelLogoImageWithTraitCollection(channel, UITraitCollection(userInterfaceIdiom: .carPlay))
    }

    static func livestreamsSections(for contentProviders: SRGContentProviders, interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        SRGDataProvider.current!.regionalizedRadioLivestreams(for: ApplicationConfiguration.shared.vendor, contentProviders: contentProviders)
            .map { medias in
                Publishers.AccumulateLatestMany(medias.map { media in
                    liveMediaDataPublisher(for: media)
                })
            }
            .switchToLatest()
            .map { liveMediaDataList in
                let items = liveMediaDataList.map { liveMediaData in
                    let item = CPListItem(text: liveMediaData.media.channel?.title, detailText: nil, image: Self.logoImage(for: liveMediaData.media))
                    item.accessoryType = .none
                    item.handler = { _, completion in
                        interfaceController.play(media: liveMediaData.media, completion: completion)
                    }
                    item.playingIndicatorLocation = .trailing
                    item.isPlaying = liveMediaData.playing
                    return item
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
        } else {
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

    static func liveProgramsSections(for channel: SRGChannel, media: SRGMedia, interfaceController _: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        liveProgramsPublisher(for: channel, media: media)
            .map { programs in
                Publishers.AccumulateLatestMany(programs.map { program in
                    liveProgramDataPublisher(for: program)
                })
            }
            .switchToLatest()
            .map { liveProgramDataList in
                let items = liveProgramDataList.map { liveProgramData -> CPListItem in
                    let program = liveProgramData.program
                    let time = "\(DateFormatter.play_time.string(from: program.startDate)) - \(DateFormatter.play_time.string(from: program.endDate))"
                    let item = CPListItem(text: liveProgramData.program.title, detailText: time, image: liveProgramData.image)
                    item.accessoryType = .none
                    item.handler = { _, completion in
                        if let mediaUrn = program.mediaURN, program.startDate <= Date() {
                            SRGLetterboxService.shared.controller?.switch(toURN: mediaUrn, withCompletionHandler: { _ in
                                completion()
                            })
                        } else {
                            completion()
                        }
                    }
                    item.playingIndicatorLocation = .trailing
                    item.isPlaying = liveProgramData.playing
                    return item
                }
                return [CPListSection(items: items)]
            }
            .eraseToAnyPublisher()
    }
}

private extension Publisher where Output == [SRGMedia] {
    func mapToSections(with interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Failure> {
        map { medias in
            Publishers.AccumulateLatestMany(medias.map { media in
                CarPlayList.mediaDataPublisher(for: media)
            })
        }
        .switchToLatest()
        .map { mediaDataList in
            let items = mediaDataList.map { mediaData in
                let item = CPListItem(text: MediaDescription.title(for: mediaData.media, style: .show),
                                      // Keep same media item height with a detail text in any cases.
                                      detailText: MediaDescription.subtitle(for: mediaData.media, style: .show) ?? " ",
                                      image: mediaData.image)
                item.accessoryType = .none
                item.handler = { _, completion in
                    interfaceController.play(media: mediaData.media, completion: completion)
                }
                item.playingIndicatorLocation = .trailing
                item.isPlaying = mediaData.playing
                item.playbackProgress = mediaData.progress ?? 0
                return item
            }
            return [CPListSection(items: items)]
        }
        .eraseToAnyPublisher()
    }
}
