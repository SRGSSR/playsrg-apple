//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

private let kDefaultNumberOfPlaceholders = 10
private let kDefaultNumberOfLivestreamPlaceholders = 4

// MARK: Types

enum Content {
    enum Section: Hashable {
        case content(SRGContentSection)
        case configured(ConfiguredSection)
        
        var properties: SectionProperties {
            switch self {
            case let .content(section):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }
    
    enum Item: Hashable {
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
        
        case highlight(_ highlight: Highlight)
        
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
            case let .highlight(highlight):
                return highlight.title
            default:
                return nil
            }
        }
        
        static func groupAlphabetically(_ items: [Item]) -> [(key: Character, value: [Item])] {
            return items.groupedAlphabetically { $0.title }
        }
    }
    
    static func medias(from items: [Content.Item]) -> [SRGMedia] {
        return items.compactMap { item in
            if case let .media(media) = item {
                return media
            }
            else {
                return nil
            }
        }
    }
    
#if os(iOS)
    static func downloads(from items: [Content.Item]) -> [Download] {
        return items.compactMap { item in
            if case let .download(download) = item {
                return download
            }
            else {
                return nil
            }
        }
    }
    
    static func notifications(from items: [Content.Item]) -> [UserNotification] {
        return items.compactMap { item in
            if case let .notification(notification) = item {
                return notification
            }
            else {
                return nil
            }
        }
    }
#endif
    
    static func shows(from items: [Content.Item]) -> [SRGShow] {
        return items.compactMap { item in
            if case let .show(show) = item {
                return show
            }
            else {
                return nil
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
    
    /// Properties for section detail display
    var displaysTitle: Bool { get }
    var supportsEdition: Bool { get }
    var emptyType: EmptyContentView.`Type` { get }
    
#if os(iOS)
    var sharingItem: SharingItem? { get }
#endif
    
    /// Analytics information
    var analyticsTitle: String? { get }
    var analyticsLevels: [String]? { get }
    var analyticsDeletionHiddenEventTitle: String? { get }
    
    /// Properties for section displayed as a row
    var rowHighlight: Highlight? { get }
    var placeholderRowItems: [Content.Item] { get }
    var displaysRowHeader: Bool { get }
    
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
        
        private var presentation: SRGContentPresentation {
            return contentSection.presentation
        }
        
        var title: String? {
            if let title = presentation.title {
                return title
            }
            else {
                switch presentation.type {
                case .favoriteShows:
                    return NSLocalizedString("Favorites", comment: "Title label used to present the TV or radio favorite shows")
                case .myProgram:
                    return NSLocalizedString("Latest episodes from your favorites", comment: "Title label used to present the latest episodes from TV favorite shows")
                case .livestreams:
                    return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
                case .continueWatching:
                    return NSLocalizedString("Resume playback", comment: "Title label used to present medias whose playback can be resumed")
                case .watchLater:
                    return NSLocalizedString("Later", comment: "Title Label used to present the video later list")
                case .showAccess:
                    return NSLocalizedString("Shows", comment: "Title label used to present the TV shows AZ and TV shows by date access buttons")
                case .topicSelector:
                    return NSLocalizedString("Topics", comment: "Title label used to present the topic list")
                default:
                    return nil
                }
            }
        }
        
        var summary: String? {
            return presentation.summary
        }
        
        var label: String? {
            return presentation.label
        }
        
        var image: SRGImage? {
            return presentation.image
        }
        
        var imageVariant: SRGImageVariant {
            guard ApplicationConfiguration.shared.arePosterImagesEnabled else { return .default }
            switch contentSection.type {
            case .shows:
                return .poster
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    return .poster
                default:
                    return .default
                }
            default:
                return .default
            }
        }
        
        var displaysTitle: Bool {
            switch contentSection.type {
            case .showAndMedias:
                return false
            default:
                return true
            }
        }
        
        var supportsEdition: Bool {
            switch contentSection.type {
            case .predefined:
                switch presentation.type {
                case .favoriteShows, .continueWatching, .watchLater:
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
        
        var emptyType: EmptyContentView.`Type` {
            switch contentSection.type {
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    return .favoriteShows
                case .myProgram:
                    return .episodesFromFavorites
                case .continueWatching:
                    return .resumePlayback
                case .watchLater:
                    return .watchLater
                default:
                    return .generic
                }
            default:
                return .generic
            }
        }
        
#if os(iOS)
        var sharingItem: SharingItem? {
            return SharingItem(for: contentSection)
        }
#endif
        
        var analyticsTitle: String? {
            switch contentSection.type {
            case .medias, .showAndMedias, .shows:
                return contentSection.presentation.title ?? contentSection.uid
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    return AnalyticsPageTitle.favorites.rawValue
                case .myProgram:
                    return AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
                case .continueWatching:
                    return AnalyticsPageTitle.resumePlayback.rawValue
                case .watchLater:
                    return AnalyticsPageTitle.watchLater.rawValue
                case .topicSelector:
                    return AnalyticsPageTitle.topics.rawValue
                default:
                    return nil
                }
            case .none:
                return nil
            }
        }
        
        var analyticsLevels: [String]? {
            switch contentSection.type {
            case .medias, .showAndMedias, .shows:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue, AnalyticsPageLevel.section.rawValue]
            case .predefined:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
            case .none:
                return nil
            }
        }
        
        var analyticsDeletionHiddenEventTitle: String? {
            switch presentation.type {
            case .favoriteShows:
                return AnalyticsTitle.favoriteRemove.rawValue
            case .watchLater:
                return AnalyticsTitle.watchLaterRemove.rawValue
            case .continueWatching:
                return AnalyticsTitle.historyRemove.rawValue
            default:
                return nil
            }
        }
        
        var rowHighlight: Highlight? {
            guard presentation.type == .highlight else { return nil }
            return Highlight(from: contentSection)
        }
        
        var placeholderRowItems: [Content.Item] {
            switch presentation.type {
            case .mediaElement:
                return [.mediaPlaceholder(index: 0)]
            case .showElement:
                return [.showPlaceholder(index: 0)]
            case .topicSelector:
                return (0..<kDefaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0) }
            case .swimlane, .mediaElementSwimlane, .heroStage, .grid:
                switch contentSection.type {
                case .showAndMedias:
                    let mediaPlaceholderItems: [Content.Item] = (1..<kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
                    return [.showPlaceholder(index: 0)].appending(contentsOf: mediaPlaceholderItems)
                case .shows:
                    return (0..<kDefaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
                default:
                    return (0..<kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
                }
            case .livestreams:
                return (0..<kDefaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .highlight:
                return (rowHighlight != nil) ? [] : (0..<kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            default:
                return []
            }
        }
        
        var displaysRowHeader: Bool {
            return contentSection.presentation.type != .highlight
        }
        
        func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error> {
            let dataProvider = SRGDataProvider.current!
            let vendor = ApplicationConfiguration.shared.vendor
            
            switch contentSection.type {
            case .medias:
                return dataProvider.medias(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, paginatedBy: paginator)
                    .map { self.filterItems($0).map { .media($0) } }
                    .eraseToAnyPublisher()
            case .showAndMedias:
                return dataProvider.showAndMedias(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, paginatedBy: paginator)
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
                return dataProvider.shows(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, paginatedBy: paginator)
                    .map { self.filterItems($0).map { .show($0) } }
                    .eraseToAnyPublisher()
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    return dataProvider.favoritesPublisher(filter: filter)
                        .map { $0.map { .show($0) } }
                        .eraseToAnyPublisher()
                case .myProgram:
                    return dataProvider.favoritesPublisher(filter: filter)
                        .map { dataProvider.latestMediasForShowsPublisher(withUrns: $0.map(\.urn), pageSize: pageSize) }
                        .switchToLatest()
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .livestreams:
                    return dataProvider.tvLivestreams(for: vendor)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .topicSelector:
                    return dataProvider.tvTopics(for: vendor)
                        .map { $0.map { .topic($0) } }
                        .eraseToAnyPublisher()
                case .continueWatching:
                    return dataProvider.resumePlaybackPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .watchLater:
                    return dataProvider.laterPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
#if os(iOS)
                case .showAccess:
                    return Just([.showAccess(radioChannel: nil)])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
#endif
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
                    return UserInteractionSignal.favoriteUpdates()
                case .continueWatching:
                    return UserInteractionSignal.historyUpdates()
                case .watchLater:
                    return UserInteractionSignal.watchLaterUpdates()
                default:
                    return Just([]).eraseToAnyPublisher()
                }
            default:
                return Just([]).eraseToAnyPublisher()
            }
        }
        
        func reloadSignal() -> AnyPublisher<Void, Never>? {
            switch presentation.type {
            case .favoriteShows, .myProgram:
                return ThrottledSignal.preferenceUpdates()
            case .watchLater:
                return ThrottledSignal.watchLaterUpdates()
            default:
                // TODO: No history updates yet for battery consumption reasons. Fix when an efficient way to
                //       broadcast and apply history updates is available.
                return nil
            }
        }
        
        func remove(_ items: [Content.Item]) {
            switch presentation.type {
            case .favoriteShows:
                Content.removeFromFavorites(items)
            case .watchLater:
                Content.removeFromWatchLater(items)
            case .continueWatching:
                Content.removeFromHistory(items)
            default:
                break
            }
        }
        
        private func filterItems<T>(_ items: [T]) -> [T] {
            guard presentation.type == .mediaElement || presentation.type == .showElement else { return items }
            
            if presentation.isRandomized, let item = items.randomElement() {
                return [item]
            }
            else if !presentation.isRandomized, let item = items.first {
                return [item]
            }
            else {
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
            case .radioAllShows, .tvAllShows:
                return NSLocalizedString("Shows", comment: "Title label used to present radio associated shows")
            case .favoriteShows, .radioFavoriteShows:
                return NSLocalizedString("Favorites", comment: "Title label used to present the radio favorite shows")
            case .radioLatest:
                return NSLocalizedString("The latest audios", comment: "Title label used to present the radio latest audios")
            case .radioLatestEpisodes:
                return NSLocalizedString("The latest episodes", comment: "Title label used to present the radio latest audio episodes")
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
                return NSLocalizedString("Resume playback", comment: "Title label used to present medias whose playback can be resumed")
            case .radioWatchLater, .watchLater:
                return NSLocalizedString("Later", comment: "Title Label used to present the audio later list")
            case let .show(show):
                return show.title
            case .tvLive:
                return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
            case .tvLiveCenter:
                return NSLocalizedString("Sport", comment: "Title label used to present live center medias")
            case .tvScheduledLivestreams:
                return NSLocalizedString("Play livestreams", comment: "Title label used to present scheduled livestream medias")
#if os(iOS)
            case .downloads:
                return NSLocalizedString("Downloads", comment: "Label to present downloads")
            case .notifications:
                return NSLocalizedString("Notifications", comment: "Title label used to present notifications")
            case .radioShowAccess:
                return NSLocalizedString("Shows", comment: "Title label used to present the radio shows AZ and radio shows by date access buttons")
#endif
            default:
                return nil
            }
        }
        
        var summary: String? {
            return nil
        }
        
        var label: String? {
            return nil
        }
        
        var image: SRGImage? {
            return nil
        }
        
        var imageVariant: SRGImageVariant {
            guard ApplicationConfiguration.shared.arePosterImagesEnabled else { return .default }
            switch configuredSection {
            case .tvAllShows:
                return .poster
            default:
                return .default
            }
        }
        
        var displaysTitle: Bool {
            switch configuredSection {
            case .show:
                return false
            default:
                return true
            }
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
        
#if os(iOS)
        var sharingItem: SharingItem? {
            switch configuredSection {
            case let .show(show):
                return SharingItem(for: show)
            default:
                return nil
            }
        }
#endif
        
        var analyticsTitle: String? {
            switch configuredSection {
            case let .show(show):
                return show.title
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
            case .tvLiveCenter:
                return AnalyticsPageTitle.sports.rawValue
            case .tvScheduledLivestreams:
                return AnalyticsPageTitle.events.rawValue
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
        
        var analyticsDeletionHiddenEventTitle: String? {
            switch configuredSection {
            case .favoriteShows, .radioFavoriteShows:
                return AnalyticsTitle.favoriteRemove.rawValue
            case .radioWatchLater, .watchLater:
                return AnalyticsTitle.watchLaterRemove.rawValue
            case .history, .radioResumePlayback:
                return AnalyticsTitle.historyRemove.rawValue
#if os(iOS)
            case .downloads:
                return AnalyticsTitle.downloadRemove.rawValue
#endif
            default:
                return nil
            }
        }
        
        var analyticsLevels: [String]? {
            switch configuredSection {
            case let .show(show):
                let level1 = (show.transmission == .radio) ? AnalyticsPageLevel.audio.rawValue : AnalyticsPageLevel.video.rawValue
                return [AnalyticsPageLevel.play.rawValue, level1, AnalyticsPageLevel.show.rawValue]
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
                }
                else {
                    return nil
                }
            case .tvAllShows:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
            case .tvLiveCenter:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue]
            case .tvScheduledLivestreams:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue]
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
        
        var rowHighlight: Highlight? {
            return nil
        }
        
        var placeholderRowItems: [Content.Item] {
            switch configuredSection {
            case .show, .history, .watchLater, .radioEpisodesForDay, .radioLatest, .radioLatestEpisodes, .radioLatestVideos,
                    .radioMostPopular, .tvEpisodesForDay, .tvLiveCenter, .tvScheduledLivestreams:
                return (0..<kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .tvLive, .radioLive, .radioLiveSatellite:
                return (0..<kDefaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .favoriteShows, .radioAllShows, .tvAllShows:
                return (0..<kDefaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
#if os(iOS)
            case .downloads:
                return (0..<kDefaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
#endif
            default:
                return []
            }
        }
        
        var displaysRowHeader: Bool {
            return true
        }
        
        func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error> {
            let dataProvider = SRGDataProvider.current!
            
            let configuration = ApplicationConfiguration.shared
            let vendor = configuration.vendor
            
            switch configuredSection {
            case let .show(show):
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
            case let .radioLatestEpisodes(channelUid: channelUid):
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
            case .tvLiveCenter:
                return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreams:
                return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize, paginatedBy: paginator)
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
