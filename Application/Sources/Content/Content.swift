//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

private let kDefaultNumberOfPlaceholders = 10
private let kDefaultNumberOfLivestreamPlaceholders = 4

// MARK: Content types

@objc enum ContentType: Int {
    case videoOrTV
    case audioOrRadio
    case mixed

    func imageVariant(mediaType: SRGContentSectionMediaType?) -> SRGImageVariant {
        switch (self, mediaType) {
        case (.videoOrTV, _):
            ApplicationConfiguration.shared.arePosterImagesEnabled ? .poster : .default
        case (.audioOrRadio, .audio):
            ApplicationConfiguration.shared.arePodcastImagesEnabled ? .podcast : .default
        case (.audioOrRadio, _):
            .default
        case (.mixed, _):
            .default
        }
    }
}

// MARK: Types

enum Content {
    enum Section: Hashable {
        case content(SRGContentSection, type: ContentType, show: SRGShow? = nil)
        case configured(ConfiguredSection)

        var properties: SectionProperties {
            switch self {
            case let .content(section, type, show):
                ContentSectionProperties(contentSection: section, contentType: type, show: show)
            case let .configured(section):
                ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }

    indirect enum Item: Hashable {
        case mediaPlaceholder(index: Int)
        case media(_ media: SRGMedia)

        case showPlaceholder(index: Int)
        case show(_ show: SRGShow)

        case topicPlaceholder(index: Int)
        case topic(_ topic: SRGTopic)

        #if os(iOS)
            case download(_ download: Download)
            case notification(_ notification: UserNotification)
            case showAccess(radioChannel: RadioChannel?)
        #endif

        case highlightPlaceholder(index: Int)
        case highlight(_ highlight: Highlight, item: Self?)

        case transparent

        private var title: String? {
            switch self {
            case let .media(media):
                return media.title
            case let .show(show):
                return show.title
            case let .topic(topic):
                return topic.title
            #if os(iOS)
                case let .download(download):
                    return download.title
                case let .notification(notification):
                    return notification.title
            #endif
            case let .highlight(highlight, _):
                return highlight.title
            default:
                return nil
            }
        }

        static func groupAlphabetically(_ items: [Self]) -> [(key: Character, value: [Self])] {
            items.groupedAlphabetically { $0.title }
        }
    }

    static func medias(from items: [Self.Item]) -> [SRGMedia] {
        items.compactMap { item in
            if case let .media(media) = item {
                media
            } else {
                nil
            }
        }
    }

    #if os(iOS)
        static func downloads(from items: [Self.Item]) -> [Download] {
            items.compactMap { item in
                if case let .download(download) = item {
                    download
                } else {
                    nil
                }
            }
        }

        static func notifications(from items: [Self.Item]) -> [UserNotification] {
            items.compactMap { item in
                if case let .notification(notification) = item {
                    notification
                } else {
                    nil
                }
            }
        }
    #endif

    static func shows(from items: [Self.Item]) -> [SRGShow] {
        items.compactMap { item in
            if case let .show(show) = item {
                show
            } else {
                nil
            }
        }
    }
}

// MARK: Section properties

protocol SectionFiltering {
    func compatibleShows(_ shows: [SRGShow]) -> [SRGShow]
    func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia]
}

protocol SectionProperties {
    /// Generic properties
    var title: String? { get }
    var summary: String? { get }
    var label: String? { get }
    var image: SRGImage? { get }
    var imageVariant: SRGImageVariant { get }
    var mediaType: SRGContentSectionMediaType? { get }

    /// Properties for section detail display
    var displaysTitle: Bool { get }
    var supportsEdition: Bool { get }
    var emptyType: EmptyContentView.`Type` { get }
    var hasHighlightedItem: Bool { get }
    var couldHaveHighlightedItem: Bool { get }

    var displayedShow: SRGShow? { get }
    #if os(iOS)
        var sharingItem: SharingItem? { get }
        var canResetApplicationBadge: Bool { get }
    #endif

    /// Analytics information
    var analyticsTitle: String? { get }
    var analyticsType: String? { get }
    var analyticsLevels: [String]? { get }
    func analyticsDeletionHiddenEvent(source: AnalyticsListSource) -> AnalyticsEvent?

    /// Properties for section displayed as a row
    var rowHighlight: Highlight? { get }
    var placeholderRowItems: [Content.Item] { get }
    var displaysRowHeader: Bool { get }
    var openContentPageId: String? { get }

    /// Publisher providing content for the section. A single result must be delivered upon subscription. Further
    /// results can be retrieved (if any) using a paginator, one page at a time.
    func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error>

    /// Publisher for interactive updates (addition / removal of items by the user).
    func interactiveUpdatesPublisher() -> AnyPublisher<[Content.Item], Never>

    /// Signal which can be used to trigger a section reload.
    func reloadSignal() -> AnyPublisher<Void, Never>?

    /// Method to be called for removing the specified items from an editable section.
    func remove(_ items: [Content.Item])
}

private extension Content {
    struct ContentSectionProperties: SectionProperties {
        let contentSection: SRGContentSection
        let contentType: ContentType
        let show: SRGShow?

        private var presentation: SRGContentPresentation {
            contentSection.presentation
        }

        var title: String? {
            if let title = presentation.title {
                title
            } else {
                switch (presentation.type, contentSection.mediaType) {
                case (.favoriteShows, _):
                    NSLocalizedString("Favorites", comment: "Title label used to present the TV or radio favorite shows")
                case (.myProgram, _):
                    NSLocalizedString("Latest episodes from your favorites", comment: "Title label used to present the latest episodes from TV favorite shows")
                case (.livestreams, .audio):
                    NSLocalizedString("Radio channels", comment: "Title label to present radio channels livestreams")
                case (.livestreams, .video):
                    NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
                case (.continueWatching, _):
                    NSLocalizedString("Resume videos playback", comment: "Title label used to present videos whose playback can be resumed")
                case (.continueStreaming, _):
                    NSLocalizedString("Resume audios playback", comment: "Title label used to present audios whose playback can be resumed")
                case (.watchLater, .audio), (.streamLater, .audio):
                    NSLocalizedString("Listen later", comment: "Title Label used to present the audio later list")
                case (.watchLater, _), (.streamLater, _):
                    NSLocalizedString("Later", comment: "Title Label used to present the video later list")
                case (.showAccess, _):
                    NSLocalizedString("Podcasts", comment: "Title label used to present the TV shows AZ and TV shows by date access buttons")
                case (.topicSelector, _):
                    NSLocalizedString("Topics", comment: "Title label used to present the topic list")
                default:
                    nil
                }
            }
        }

        var summary: String? {
            presentation.summary
        }

        var label: String? {
            presentation.label
        }

        var image: SRGImage? {
            presentation.image
        }

        var imageVariant: SRGImageVariant {
            switch (contentSection.type, presentation.type) {
            case (.shows, _):
                contentType.imageVariant(mediaType: contentSection.mediaType)
            case (.predefined, .favoriteShows):
                contentType.imageVariant(mediaType: contentSection.mediaType)
            default:
                .default
            }
        }

        var displaysTitle: Bool {
            switch contentSection.type {
            case .showAndMedias:
                false
            default:
                true
            }
        }

        var supportsEdition: Bool {
            switch contentSection.type {
            case .predefined:
                switch presentation.type {
                case .favoriteShows, .continueWatching, .watchLater, .streamLater, .continueStreaming:
                    true
                default:
                    false
                }
            default:
                false
            }
        }

        var emptyType: EmptyContentView.`Type` {
            switch contentSection.type {
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    .favoriteShows
                case .myProgram:
                    .episodesFromFavorites
                case .continueWatching, .continueStreaming:
                    .resumePlayback
                case .watchLater, .streamLater:
                    .watchLater
                default:
                    .generic
                }
            default:
                .generic
            }
        }

        var hasHighlightedItem: Bool {
            presentation.type == .showPromotion
        }

        var couldHaveHighlightedItem: Bool {
            presentation.type == .highlight
        }

        var displayedShow: SRGShow? {
            show
        }

        #if os(iOS)
            var sharingItem: SharingItem? {
                SharingItem(for: contentSection)
            }

            var canResetApplicationBadge: Bool {
                false
            }
        #endif

        var analyticsTitle: String? {
            switch contentSection.type {
            case .medias, .showAndMedias, .shows:
                contentSection.presentation.title ?? contentSection.uid
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    AnalyticsPageTitle.favorites.rawValue
                case .myProgram:
                    AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
                case .continueWatching, .continueStreaming:
                    AnalyticsPageTitle.resumePlayback.rawValue
                case .watchLater, .streamLater:
                    AnalyticsPageTitle.watchLater.rawValue
                case .topicSelector:
                    AnalyticsPageTitle.topics.rawValue
                default:
                    nil
                }
            case .none:
                nil
            }
        }

        var analyticsType: String? {
            switch contentSection.type {
            case .none:
                nil
            default:
                AnalyticsPageType.detail.rawValue
            }
        }

        var analyticsLevels: [String]? {
            switch contentSection.type {
            case .medias, .showAndMedias, .shows:
                [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue, AnalyticsPageLevel.section.rawValue]
            case .predefined:
                [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
            case .none:
                nil
            }
        }

        func analyticsDeletionHiddenEvent(source: AnalyticsListSource) -> AnalyticsEvent? {
            switch presentation.type {
            case .favoriteShows:
                AnalyticsEvent.favorite(action: .remove, source: source, urn: nil)
            case .watchLater, .streamLater:
                AnalyticsEvent.watchLater(action: .remove, source: source, urn: nil)
            case .continueWatching, .continueStreaming:
                AnalyticsEvent.historyRemove(source: source, urn: nil)
            default:
                nil
            }
        }

        var rowHighlight: Highlight? {
            guard presentation.type == .highlight || presentation.type == .showPromotion else { return nil }
            return Highlight(from: contentSection)
        }

        var placeholderRowItems: [Content.Item] {
            switch presentation.type {
            case .mediaElement:
                return [.mediaPlaceholder(index: 0)]
            case .showElement:
                return [.showPlaceholder(index: 0)]
            case .topicSelector:
                return (0 ..< kDefaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0) }
            case .swimlane, .mediaElementSwimlane, .heroStage, .grid, .availableEpisodes:
                switch contentSection.type {
                case .showAndMedias:
                    let mediaPlaceholderItems: [Content.Item] = (1 ..< kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
                    return [.showPlaceholder(index: 0)].appending(contentsOf: mediaPlaceholderItems)
                case .shows:
                    return (0 ..< kDefaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
                default:
                    return (0 ..< kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
                }
            case .livestreams:
                return (0 ..< kDefaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .highlight:
                return (rowHighlight != nil) ? [.highlightPlaceholder(index: 0)] : (0 ..< kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .showPromotion:
                return (rowHighlight != nil) ? [.highlightPlaceholder(index: 0)] : (0 ..< kDefaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
            default:
                return []
            }
        }

        var displaysRowHeader: Bool {
            contentSection.presentation.type != .highlight && contentSection.presentation.type != .showPromotion
        }

        var openContentPageId: String? {
            guard let link = contentSection.presentation.contentLink, link.type == .microPage, let id = link.target else {
                return nil
            }

            return id
        }

        var mediaType: SRGContentSectionMediaType? {
            contentSection.mediaType
        }

        func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error> {
            let dataProvider = SRGDataProvider.current!

            switch contentSection.type {
            case .medias:
                return dataProvider.medias(for: contentSection.vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, paginatedBy: paginator)
                    .map { filterItems($0).map { .media($0) } }
                    .eraseToAnyPublisher()
            case .showAndMedias:
                return dataProvider.showAndMedias(for: contentSection.vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, paginatedBy: paginator)
                    .map {
                        var items = [Content.Item]()
                        if let show = $0.show {
                            items.append(.show(show))
                        }
                        items.append(contentsOf: $0.medias.map { .media($0) })
                        return items
                    }
                    .eraseToAnyPublisher()
            case .shows:
                return dataProvider.shows(for: contentSection.vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, paginatedBy: paginator)
                    .map { filterItems($0).map { .show($0) } }
                    .eraseToAnyPublisher()
            case .predefined:
                switch (presentation.type, contentSection.mediaType) {
                case (.favoriteShows, _):
                    return dataProvider.favoritesPublisher(filter: filter)
                        .map { $0.map { .show($0) } }
                        .eraseToAnyPublisher()
                case (.myProgram, _):
                    return dataProvider.favoritesPublisher(filter: filter)
                        .map { dataProvider.latestMediasForShowsPublisher(withUrns: $0.map(\.urn), pageSize: pageSize) }
                        .switchToLatest()
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case (.livestreams, .audio):
                    return dataProvider.radioLivestreams(for: contentSection.vendor, contentProviders: .all)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case (.livestreams, .video):
                    return dataProvider.tvLivestreams(for: contentSection.vendor)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case (.topicSelector, _):
                    return dataProvider.tvTopics(for: contentSection.vendor)
                        .map { $0.map { .topic($0) } }
                        .eraseToAnyPublisher()
                case (.continueWatching, _), (.continueStreaming, _):
                    return dataProvider.resumePlaybackPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case (.watchLater, _), (.streamLater, _):
                    return dataProvider.laterPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                #if os(iOS)
                    case (.showAccess, _):
                        return Just([.showAccess(radioChannel: nil)])
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                #endif
                case (.availableEpisodes, _):
                    if let show {
                        return dataProvider.latestMediasForShow(withUrn: show.urn, pageSize: pageSize, paginatedBy: paginator)
                            .map { $0.map { .media($0) } }
                            .eraseToAnyPublisher()
                    } else {
                        return Just([])
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                default:
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            case .none:
                return Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        }

        func interactiveUpdatesPublisher() -> AnyPublisher<[Content.Item], Never> {
            switch contentSection.type {
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows, .myProgram:
                    UserInteractionSignal.favoriteUpdates()
                case .continueWatching, .continueStreaming:
                    UserInteractionSignal.historyUpdates()
                case .watchLater, .streamLater:
                    UserInteractionSignal.watchLaterUpdates()
                default:
                    Just([]).eraseToAnyPublisher()
                }
            default:
                Just([]).eraseToAnyPublisher()
            }
        }

        func reloadSignal() -> AnyPublisher<Void, Never>? {
            switch presentation.type {
            case .favoriteShows, .myProgram:
                ThrottledSignal.preferenceUpdates()
            case .watchLater, .streamLater:
                ThrottledSignal.watchLaterUpdates()
            default:
                // TODO: No history updates yet for battery consumption reasons. Fix when an efficient way to
                //       broadcast and apply history updates is available.
                nil
            }
        }

        func remove(_ items: [Content.Item]) {
            switch presentation.type {
            case .favoriteShows:
                Content.removeFromFavorites(items)
            case .watchLater, .streamLater:
                Content.removeFromWatchLater(items)
            case .continueWatching, .continueStreaming:
                Content.removeFromHistory(items)
            default:
                break
            }
        }

        private func filterItems<T>(_ items: [T]) -> [T] {
            guard presentation.type == .mediaElement || presentation.type == .showElement else { return items }

            if presentation.isRandomized, let item = items.randomElement() {
                return [item]
            } else if !presentation.isRandomized, let item = items.first {
                return [item]
            } else {
                return []
            }
        }
    }
}

// MARK: Configured section properties

private extension Content {
    struct ConfiguredSectionProperties: SectionProperties {
        let configuredSection: ConfiguredSection

        var title: String? {
            switch configuredSection {
            case .history:
                return NSLocalizedString("History", comment: "Title label used to present the history")
            case .tvAllShows:
                return NSLocalizedString("Shows", comment: "Title label used to present radio associated shows")
            case let .radioAllShows(channelUid):
                if ApplicationConfiguration.shared.channel(forUid: channelUid)?.showType == .podcast {
                    return NSLocalizedString("Podcasts", comment: "Title label used to present radio associated podcasts")
                } else {
                    return NSLocalizedString("Shows", comment: "Title label used to present radio associated shows")
                }
            case .favoriteShows, .radioFavoriteShows:
                return NSLocalizedString("Favorites", comment: "Title label used to present the radio favorite shows")
            case .radioLatest:
                return NSLocalizedString("The latest audios", comment: "Title label used to present the radio latest audios")
            case let .radioLatestEpisodes(channelUid):
                if ApplicationConfiguration.shared.channel(forUid: channelUid)?.showType == .podcast {
                    return NSLocalizedString("Latest podcasts", comment: "Title label used to present the radio latest podcast episodes")
                } else {
                    return NSLocalizedString("The latest episodes", comment: "Title label used to present the radio latest audio episodes")
                }
            case .radioLatestEpisodesFromFavorites:
                return NSLocalizedString("Latest episodes from your favorites", comment: "Title label used to present the latest episodes from radio favorite shows")
            case .radioLatestVideos:
                return NSLocalizedString("Latest videos", comment: "Title label used to present the radio latest videos")
            case .radioLive:
                return NSLocalizedString("Radio channels", comment: "Title label to present main radio livestreams")
            case .radioLiveSatellite:
                return NSLocalizedString("Music radios", comment: "Title label to present musical Swiss satellite radios")
            case .radioMostPopular:
                return NSLocalizedString("Most listened to", comment: "Title label used to present the radio most popular audio medias")
            case .radioResumePlayback:
                return NSLocalizedString("Resume audios playback", comment: "Title label used to present audios whose playback can be resumed")
            case .radioWatchLater:
                return NSLocalizedString("Listen later", comment: "Title Label used to present the audio later list")
            case .watchLater:
                return NSLocalizedString("Later", comment: "Title Label used to present the video later list")
            case .tvLive:
                return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
            case .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll:
                return NSLocalizedString("Sport livestreams", comment: "Title label used to present scheduled livestreams medias from live center (Sport manager)")
            case .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll:
                return NSLocalizedString("Past sport livestreams", comment: "Title label used to present on demand medias from live center (Sport manager)")
            case .tvScheduledLivestreams:
                return NSLocalizedString("Play livestreams", comment: "Title label used to present scheduled livestream medias")
            case .tvScheduledLivestreamsNews:
                return NSLocalizedString("News livestreams", comment: "Title label used to present news scheduled livestream medias")
            case .tvScheduledLivestreamsSport:
                return NSLocalizedString("Sport livestreams", comment: "Title label used to present sport scheduled livestream medias")
            case .tvScheduledLivestreamsSignLanguage:
                return NSLocalizedString("Sign language livestreams", comment: "Title label used to present sign language scheduled livestream medias")
            #if os(iOS)
                case .downloads:
                    return NSLocalizedString("Downloads", comment: "Label to present downloads")
                case .notifications:
                    return NSLocalizedString("Notifications", comment: "Title label used to present notifications")
                case let .radioShowAccess(channelUid):
                    if ApplicationConfiguration.shared.channel(forUid: channelUid)?.showType == .podcast {
                        return NSLocalizedString("Podcasts", comment: "Title label used to present radio associated podcasts")
                    } else {
                        return NSLocalizedString("Shows", comment: "Title label used to present the radio shows AZ and radio shows by date access buttons")
                    }
            #endif
            default:
                return nil
            }
        }

        var summary: String? {
            nil
        }

        var label: String? {
            nil
        }

        var image: SRGImage? {
            nil
        }

        var imageVariant: SRGImageVariant {
            switch configuredSection {
            // swiftlint:disable:next line_length
            case .availableEpisodes, .history, .watchLater, .tvEpisodesForDay, .tvLive, .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll, .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll, .tvScheduledLivestreams, .tvScheduledLivestreamsNews, .tvScheduledLivestreamsSport, .tvScheduledLivestreamsSignLanguage:
                ContentType.videoOrTV.imageVariant(mediaType: mediaType)
            case .radioEpisodesForDay, .radioFavoriteShows, .radioLatest, .radioLatestEpisodes, .radioLatestEpisodesFromFavorites, .radioMostPopular, .radioResumePlayback, .radioWatchLater, .radioLive, .radioLiveSatellite, .radioAllShows:
                ContentType.audioOrRadio.imageVariant(mediaType: mediaType)
            case .radioLatestVideos, .tvAllShows, .favoriteShows:
                ContentType.mixed.imageVariant(mediaType: mediaType)
            #if os(iOS)
                case .downloads, .notifications:
                    ContentType.videoOrTV.imageVariant(mediaType: mediaType)
                case .radioShowAccess:
                    ContentType.audioOrRadio.imageVariant(mediaType: mediaType)
            #endif
            }
        }

        var displaysTitle: Bool {
            true
        }

        var supportsEdition: Bool {
            switch configuredSection {
            case .favoriteShows, .history, .radioFavoriteShows, .radioResumePlayback, .radioWatchLater, .watchLater:
                return true
            #if os(iOS)
                case .downloads, .notifications:
                    return true
            #endif
            default:
                return false
            }
        }

        var emptyType: EmptyContentView.`Type` {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows:
                return .favoriteShows
            case .radioLatestEpisodes:
                return .episodesFromFavorites
            case .radioWatchLater, .watchLater:
                return .watchLater
            case .history:
                return .history
            case .radioResumePlayback:
                return .resumePlayback
            #if os(iOS)
                case .downloads:
                    return .downloads
                case .notifications:
                    return .notifications
            #endif
            default:
                return .generic
            }
        }

        var hasHighlightedItem: Bool {
            false
        }

        var couldHaveHighlightedItem: Bool {
            false
        }

        var displayedShow: SRGShow? {
            if case let .availableEpisodes(show) = configuredSection {
                show
            } else {
                nil
            }
        }

        #if os(iOS)
            var sharingItem: SharingItem? {
                switch configuredSection {
                case let .availableEpisodes(show):
                    SharingItem(for: show)
                default:
                    nil
                }
            }

            var canResetApplicationBadge: Bool {
                switch configuredSection {
                case .notifications:
                    true
                default:
                    false
                }
            }
        #endif

        var analyticsTitle: String? {
            switch configuredSection {
            case .history:
                return AnalyticsPageTitle.history.rawValue
            case .radioAllShows, .tvAllShows:
                return AnalyticsPageTitle.showsAZ.rawValue
            case .favoriteShows, .radioFavoriteShows:
                return AnalyticsPageTitle.favorites.rawValue
            case .radioLatest, .radioLatestVideos:
                return AnalyticsPageTitle.latest.rawValue
            case .radioLatestEpisodes:
                return AnalyticsPageTitle.latestEpisodes.rawValue
            case .radioLatestEpisodesFromFavorites:
                return AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
            case .radioMostPopular:
                return AnalyticsPageTitle.mostPopular.rawValue
            case .radioResumePlayback:
                return AnalyticsPageTitle.resumePlayback.rawValue
            case .radioWatchLater, .watchLater:
                return AnalyticsPageTitle.watchLater.rawValue
            case .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll, .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll:
                return AnalyticsPageTitle.sports.rawValue
            case .tvScheduledLivestreams, .tvScheduledLivestreamsNews, .tvScheduledLivestreamsSport, .tvScheduledLivestreamsSignLanguage:
                return AnalyticsPageTitle.scheduledLivestreams.rawValue
            #if os(iOS)
                case .downloads:
                    return AnalyticsPageTitle.downloads.rawValue
                case .notifications:
                    return AnalyticsPageTitle.notifications.rawValue
            #endif
            default:
                return nil
            }
        }

        var analyticsType: String? {
            switch configuredSection {
            case .radioAllShows, .tvAllShows:
                AnalyticsPageType.overview.rawValue
            case .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll, .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll,
                 .tvScheduledLivestreams, .tvScheduledLivestreamsNews, .tvScheduledLivestreamsSport, .tvScheduledLivestreamsSignLanguage,
                 .tvLive, .radioLive, .radioLiveSatellite:
                AnalyticsPageType.live.rawValue
            default:
                AnalyticsPageType.detail.rawValue
            }
        }

        var analyticsLevels: [String]? {
            switch configuredSection {
            case let .radioAllShows(channelUid),
                 let .radioFavoriteShows(channelUid: channelUid),
                 let .radioLatest(channelUid: channelUid),
                 let .radioLatestEpisodes(channelUid: channelUid),
                 let .radioLatestEpisodesFromFavorites(channelUid: channelUid),
                 let .radioLatestVideos(channelUid: channelUid),
                 let .radioMostPopular(channelUid: channelUid),
                 let .radioResumePlayback(channelUid: channelUid),
                 let .radioWatchLater(channelUid: channelUid):
                if let channel = ApplicationConfiguration.shared.radioChannel(forUid: channelUid) {
                    return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.audio.rawValue, channel.name]
                } else {
                    return nil
                }
            case .tvAllShows:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
            case .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue, AnalyticsPageLevel.scheduledLivestream.rawValue]
            case .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue, AnalyticsPageLevel.episode.rawValue]
            case .tvScheduledLivestreams:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue]
            case .tvScheduledLivestreamsNews:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue, AnalyticsPageLevel.news.rawValue]
            case .tvScheduledLivestreamsSport:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue, AnalyticsPageLevel.sport.rawValue]
            case .tvScheduledLivestreamsSignLanguage:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue, AnalyticsPageLevel.signLanguage.rawValue]
            case .favoriteShows, .history, .watchLater:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.user.rawValue]
            #if os(iOS)
                case .downloads, .notifications:
                    return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.user.rawValue]
            #endif
            default:
                return nil
            }
        }

        func analyticsDeletionHiddenEvent(source: AnalyticsListSource) -> AnalyticsEvent? {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows:
                return AnalyticsEvent.favorite(action: .remove, source: source, urn: nil)
            case .radioWatchLater, .watchLater:
                return AnalyticsEvent.watchLater(action: .remove, source: source, urn: nil)
            case .history, .radioResumePlayback:
                return AnalyticsEvent.historyRemove(source: source, urn: nil)
            #if os(iOS)
                case .downloads:
                    return AnalyticsEvent.download(action: .remove, source: source, urn: nil)
            #endif
            default:
                return nil
            }
        }

        var rowHighlight: Highlight? {
            nil
        }

        var placeholderRowItems: [Content.Item] {
            switch configuredSection {
            case .availableEpisodes, .history, .watchLater, .radioEpisodesForDay, .radioLatest, .radioLatestEpisodes, .radioLatestVideos,
                 .radioMostPopular, .tvEpisodesForDay, .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll,
                 .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll, .tvScheduledLivestreams, .tvScheduledLivestreamsNews, .tvScheduledLivestreamsSport, .tvScheduledLivestreamsSignLanguage:
                return (0 ..< kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .tvLive, .radioLive, .radioLiveSatellite:
                return (0 ..< kDefaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .favoriteShows, .radioAllShows, .tvAllShows:
                return (0 ..< kDefaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
            #if os(iOS)
                case .downloads:
                    return (0 ..< kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            #endif
            default:
                return []
            }
        }

        var displaysRowHeader: Bool {
            true
        }

        var openContentPageId: String? {
            nil
        }

        var mediaType: SRGContentSectionMediaType? {
            switch configuredSection {
            // swiftlint:disable:next line_length
            case .availableEpisodes, .favoriteShows, .history, .watchLater, .tvAllShows, .tvEpisodesForDay, .tvLive, .tvLiveCenterScheduledLivestreams, .tvLiveCenterScheduledLivestreamsAll, .tvLiveCenterEpisodes, .tvLiveCenterEpisodesAll, .tvScheduledLivestreams, .tvScheduledLivestreamsNews, .tvScheduledLivestreamsSport, .tvScheduledLivestreamsSignLanguage:
                .video
            case .radioEpisodesForDay, .radioFavoriteShows, .radioLatest, .radioLatestEpisodes, .radioLatestEpisodesFromFavorites, .radioMostPopular, .radioResumePlayback, .radioWatchLater, .radioLive, .radioLiveSatellite, .radioAllShows:
                .audio
            case .radioLatestVideos:
                .video
            #if os(iOS)
                case .downloads, .notifications:
                    .video
                case .radioShowAccess:
                    .audio
            #endif
            }
        }

        func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error> {
            let dataProvider = SRGDataProvider.current!

            let configuration = ApplicationConfiguration.shared
            let vendor = configuration.vendor

            switch configuredSection {
            case let .availableEpisodes(show):
                return dataProvider.latestMediasForShow(withUrn: show.urn, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .favoriteShows:
                return dataProvider.favoritesPublisher(filter: nil)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case .history:
                return dataProvider.historyPublisher(pageSize: pageSize, paginatedBy: paginator, filter: nil)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .watchLater:
                return dataProvider.laterPublisher(pageSize: pageSize, paginatedBy: paginator, filter: nil)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvAllShows:
                return dataProvider.tvShows(for: vendor, pageSize: SRGDataProviderUnlimitedPageSize, paginatedBy: paginator)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case let .radioAllShows(channelUid):
                return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize, paginatedBy: paginator)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case let .radioEpisodesForDay(day, channelUid: channelUid):
                return dataProvider.radioEpisodes(for: vendor, channelUid: channelUid, day: day, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioFavoriteShows:
                return dataProvider.favoritesPublisher(filter: filter)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatest(channelUid: channelUid):
                return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatestEpisodes(channelUid):
                return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioLatestEpisodesFromFavorites:
                return dataProvider.favoritesPublisher(filter: filter)
                    .map { dataProvider.latestMediasForShowsPublisher(withUrns: $0.map(\.urn), pageSize: pageSize) }
                    .switchToLatest()
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatestVideos(channelUid: channelUid):
                return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioLive:
                return dataProvider.regionalizedRadioLivestreams(for: vendor)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioLiveSatellite:
                return dataProvider.regionalizedRadioLivestreams(for: vendor, contentProviders: .swissSatelliteRadio)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioMostPopular(channelUid: channelUid):
                return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioResumePlayback:
                return dataProvider.resumePlaybackPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .radioWatchLater:
                return dataProvider.laterPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .tvEpisodesForDay(day):
                return dataProvider.tvEpisodes(for: vendor, day: day, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvLive:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenterScheduledLivestreams:
                return dataProvider.liveCenterVideos(for: vendor, contentTypeFilter: .scheduledLivestream, eventsWithResultOnly: true, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenterScheduledLivestreamsAll:
                return dataProvider.liveCenterVideos(for: vendor, contentTypeFilter: .scheduledLivestream, eventsWithResultOnly: false, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenterEpisodes:
                return dataProvider.liveCenterVideos(for: vendor, contentTypeFilter: .episode, eventsWithResultOnly: true, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenterEpisodesAll:
                return dataProvider.liveCenterVideos(for: vendor, contentTypeFilter: .episode, eventsWithResultOnly: false, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreams:
                return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreamsNews:
                return dataProvider.tvScheduledLivestreams(for: vendor, eventType: .news, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreamsSport:
                return dataProvider.tvScheduledLivestreams(for: vendor, eventType: .sport, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreamsSignLanguage:
                return dataProvider.tvScheduledLivestreams(for: vendor, signLanguageOnly: true, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            #if os(iOS)
                case .downloads:
                    return Just(Download.downloads)
                        .map { $0.map { .download($0) } }
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case .notifications:
                    return Just(UserNotification.notifications)
                        .map { $0.map { .notification($0) } }
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case let .radioShowAccess(channelUid):
                    return Just([.showAccess(radioChannel: configuration.radioChannel(forUid: channelUid))])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
            #endif
            }
        }

        func interactiveUpdatesPublisher() -> AnyPublisher<[Content.Item], Never> {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows, .radioLatestEpisodesFromFavorites:
                return UserInteractionSignal.favoriteUpdates()
            case .history, .radioResumePlayback:
                return UserInteractionSignal.historyUpdates()
            case .radioWatchLater, .watchLater:
                return UserInteractionSignal.watchLaterUpdates()
            #if os(iOS)
                case .downloads:
                    return UserInteractionSignal.downloadUpdates()
                case .notifications:
                    return UserInteractionSignal.notificationUpdates()
            #endif
            default:
                return Just([]).eraseToAnyPublisher()
            }
        }

        func reloadSignal() -> AnyPublisher<Void, Never>? {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows, .radioLatestEpisodesFromFavorites:
                return ThrottledSignal.preferenceUpdates()
            case .radioWatchLater, .watchLater:
                return ThrottledSignal.watchLaterUpdates()
            case .radioLive:
                return ApplicationSignal.settingUpdates(at: \.PlaySRGSettingSelectedLivestreamURNForChannels)
            #if os(iOS)
                case .downloads:
                    return ThrottledSignal.downloadUpdates()
            #endif
            default:
                // TODO: No history updates yet for battery consumption reasons. Fix when an efficient way to
                //       broadcast and apply history updates is available.
                return nil
            }
        }

        func remove(_ items: [Content.Item]) {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows:
                Content.removeFromFavorites(items)
            case .radioWatchLater, .watchLater:
                Content.removeFromWatchLater(items)
            case .history, .radioResumePlayback:
                Content.removeFromHistory(items)
            #if os(iOS)
                case .downloads:
                    Content.removeFromDownloads(items)
                case .notifications:
                    Content.removeFromNotifications(items)
            #endif
            default:
                break
            }
        }
    }
}

// MARK: Removal

private extension Content {
    static func removeFromFavorites(_ items: [Content.Item]) {
        let shows = Content.shows(from: items)
        FavoritesRemoveShows(shows)
    }

    static func removeFromHistory(_ items: [Content.Item]) {
        let medias = Content.medias(from: items)
        HistoryRemoveMedias(medias) { _ in }
    }

    #if os(iOS)
        static func removeFromNotifications(_ items: [Content.Item]) {
            let notifications = Content.notifications(from: items)
            let updatedNotifications = Array(Set(UserNotification.notifications).subtracting(notifications))
            UserNotification.saveNotifications(updatedNotifications)
            UserInteractionEvent.removeFromNotifications(notifications)
        }
    #endif

    static func removeFromWatchLater(_ items: [Content.Item]) {
        let medias = Content.medias(from: items)
        WatchLaterRemoveMedias(medias) { _ in }
    }

    #if os(iOS)
        static func removeFromDownloads(_ items: [Content.Item]) {
            let downloads = Content.downloads(from: items)
            Download.removeDownloads(downloads)
        }
    #endif
}
