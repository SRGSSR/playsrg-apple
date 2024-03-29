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
    case livePrograms(channel: SRGChannel, media: SRGMedia)
    
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
        case .livePrograms:
            return NSLocalizedString("Previous shows", comment: "Livestream previous programs screen title")
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
        case .livePrograms:
            return AnalyticsPageTitle.livePrograms.rawValue
        }
    }
    
    var pageViewType: String? {
        switch self {
        case .latestEpisodesFromFavorites, .livePrograms, .mostPopularMedias:
            return AnalyticsPageType.detail.rawValue
        case .livestreams:
            return AnalyticsPageType.live.rawValue
        case .mostPopular:
            return AnalyticsPageType.overview.rawValue
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
        case let .livePrograms(channel, _):
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
        case let .livePrograms(channel, media):
            return Publishers.PublishAndRepeat(onOutputFrom: Timer.publish(every: 30, on: .main, in: .common).autoconnect()) {
                return Self.liveProgramsSections(for: channel, media: media, interfaceController: interfaceController)
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
        return playingPublisher(for: media.urn)
            .map { playing in
                return LiveMediaData(media: media, playing: playing)
            }
            .eraseToAnyPublisher()
    }
    
    static func liveProgramDataPublisher(for program: SRGProgram) -> AnyPublisher<LiveProgramData, Never> {
        return Publishers.CombineLatest(
            imagePublisher(for: program),
            playingPublisher(for: program.mediaURN)
        )
        .map { image, playing in
            return LiveProgramData(program: program, image: image, playing: playing)
        }
        .eraseToAnyPublisher()
    }
    
    static func mediaDataPublisher(for media: SRGMedia) -> AnyPublisher<MediaData, Never> {
        return Publishers.CombineLatest3(
            imagePublisher(for: media),
            playingPublisher(for: media.urn),
            UserDataPublishers.playbackProgressPublisher(for: media)
        )
        .map { image, playing, progress in
            return MediaData(media: media, image: image, playing: playing, progress: progress)
        }
        .eraseToAnyPublisher()
    }
    
    private static func playingPublisher(for mediaUrn: String?) -> AnyPublisher<Bool, Never> {
        if let mediaUrn {
            return nowPlayingMediaPublisher()
                .map { $0.map(\.urn).contains(mediaUrn) }
                .eraseToAnyPublisher()
        }
        else {
            return Just(false)
                .eraseToAnyPublisher()
        }
    }
    
    private static func imagePublisher(for media: SRGMedia) -> AnyPublisher<UIImage, Never> {
        return imagePublisher(for: media.image)
    }
    
    private static func imagePublisher(for program: SRGProgram) -> AnyPublisher<UIImage, Never> {
        return imagePublisher(for: program.image)
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
        }
        else {
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
        return SRGLetterboxService.shared.publisher(for: \.controller)
            .map { controller in
                if let controller {
                    return NotificationCenter.default.weakPublisher(for: .SRGLetterboxMetadataDidChange, object: controller)
                        .map { notification in
                            let controller = notification.object as? SRGLetterboxController
                            return nowPlayingMedia(for: controller)
                        }
                        .prepend(nowPlayingMedia(for: controller))
                        .eraseToAnyPublisher()
                }
                else {
                    return Just([])
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
            return SRGDataProvider.current!.radioLatestPrograms(for: ApplicationConfiguration.shared.vendor,
                                                                channelUid: channel.uid,
                                                                livestreamUid: media.uid,
                                                                from: nil, to: nil,
                                                                pageSize: 50, paginatedBy: nil)
            .map { _, programs in
                return programs
                    .filter { $0.startDate >= dateInterval.start && $0.startDate <= dateInterval.end }
                    .reversed()
            }
            .eraseToAnyPublisher()
        }
        else {
            return Just([])
                .setFailureType(to: Error.self)
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
    
    static func liveProgramsSections(for channel: SRGChannel, media: SRGMedia, interfaceController: CPInterfaceController) -> AnyPublisher<[CPListSection], Error> {
        return liveProgramsPublisher(for: channel, media: media)
            .map { programs in
                return Publishers.AccumulateLatestMany(programs.map { program in
                    return liveProgramDataPublisher(for: program)
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
                        }
                        else {
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
        return map { medias in
            return Publishers.AccumulateLatestMany(medias.map { media in
                return CarPlayList.mediaDataPublisher(for: media)
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
