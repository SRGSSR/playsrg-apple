//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

private let defaultNumberOfPlaceholders = 10
private let defaultNumberOfLivestreamPlaceholders = 4

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
        
        @available(tvOS, unavailable)
        case showAccess(radioChannel: RadioChannel?)
        
        case transparent
        
        private var title: String? {
            switch self {
            case let .media(media):
                return media.title
            case let .show(show):
                return show.title
            case let .topic(topic):
                return topic.title
            case .mediaPlaceholder, .showPlaceholder, .topicPlaceholder, .showAccess, .transparent:
                return nil
            }
        }
        
        static func groupAlphabetically(_ items: [Item]) -> [(key: Character, value: [Item])] {
            return items.groupedAlphabetically { $0.title }
        }
    }
    
    enum EmptyType: Hashable {
        case favoriteShows
        case episodesFromFavorites
        case history
        case resumePlayback
        case watchLater
        case generic
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
    var title: String? { get }
    var summary: String? { get }
    var label: String? { get }
    var placeholderItems: [Content.Item] { get }
    var displaysTitle: Bool { get }
    var supportsEdition: Bool { get }
    var emptyType: Content.EmptyType { get }
    var imageType: SRGImageType { get }
    
    var analyticsTitle: String? { get }
    var analyticsLevels: [String]? { get }
    var analyticsDeletionHiddenEventTitle: String? { get }
    
    #if os(iOS)
    var sharingItem: SharingItem? { get }
    #endif
    
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
                case .personalizedProgram:
                    return NSLocalizedString("Latest episodes from your favorites", comment: "Title label used to present the latest episodes from TV favorite shows")
                case .livestreams:
                    return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
                case .resumePlayback:
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
        
        var placeholderItems: [Content.Item] {
            switch presentation.type {
            case .mediaHighlight:
                return [.mediaPlaceholder(index: 0)]
            case .showHighlight:
                return [.showPlaceholder(index: 0)]
            case .topicSelector:
                return (0..<defaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0) }
            case .swimlane, .mediaHighlightSwimlane, .hero, .grid:
                switch contentSection.type {
                case .showAndMedias:
                    let mediaPlaceholderItems: [Content.Item] = (1..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
                    return [.showPlaceholder(index: 0)].appending(contentsOf: mediaPlaceholderItems)
                case .shows:
                    return (0..<defaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
                case .none, .medias, .predefined:
                    return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
                }
            case .livestreams:
                return (0..<defaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .none, .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram, .showAccess:
                return []
            }
        }
        
        var displaysTitle: Bool {
            return contentSection.type != .showAndMedias
        }
        
        var supportsEdition: Bool {
            switch contentSection.type {
            case .medias, .showAndMedias, .shows:
                return false
            case .predefined:
                switch presentation.type {
                case .favoriteShows, .resumePlayback, .watchLater:
                    return true
                default:
                    return false
                }
            case .none:
                return false
            }
        }
        
        var emptyType: Content.EmptyType {
            switch contentSection.type {
            case .predefined:
                switch contentSection.presentation.type {
                case .favoriteShows:
                    return .favoriteShows
                case .personalizedProgram:
                    return .episodesFromFavorites
                case .resumePlayback:
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

        var imageType: SRGImageType {
            guard ApplicationConfiguration.shared.arePosterImagesEnabled else { return .default }
            switch contentSection.type {
            case .shows:
                return .showPoster
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    return .showPoster
                default:
                    return .default
                }
            default:
                return .default
            }
        }
        
        var analyticsTitle: String? {
            switch contentSection.type {
            case .medias, .showAndMedias, .shows:
                return contentSection.presentation.title ?? contentSection.uid
            case .predefined:
                switch presentation.type {
                case .favoriteShows:
                    return AnalyticsPageTitle.favorites.rawValue
                case .personalizedProgram:
                    return AnalyticsPageTitle.latestEpisodesFromFavorites.rawValue
                case .resumePlayback:
                    return AnalyticsPageTitle.resumePlayback.rawValue
                case .watchLater:
                    return AnalyticsPageTitle.watchLater.rawValue
                case .topicSelector:
                    return AnalyticsPageTitle.topics.rawValue
                case .none, .livestreams, .showAccess, .swimlane, .hero, .grid, .mediaHighlight, .mediaHighlightSwimlane, .showHighlight:
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
            case .resumePlayback:
                return AnalyticsTitle.historyRemove.rawValue
            default:
                return nil
            }
        }
        
        #if os(iOS)
        var sharingItem: SharingItem? {
            return SharingItem(for: contentSection)
        }
        #endif
        
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
                case .personalizedProgram:
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
                case .resumePlayback:
                    return dataProvider.resumePlaybackPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .watchLater:
                    return dataProvider.laterPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
                        .map { $0.map { .media($0) } }
                        .eraseToAnyPublisher()
                case .showAccess:
                    #if os(iOS)
                    return Just([.showAccess(radioChannel: nil)])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                    #else
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                    #endif
                case .none, .swimlane, .hero, .grid, .mediaHighlight, .mediaHighlightSwimlane, .showHighlight:
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
                case .favoriteShows, .personalizedProgram:
                    return UserInteractionSignal.favoriteUpdates()
                case .resumePlayback:
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
            case .favoriteShows, .personalizedProgram:
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
            case .resumePlayback:
                Content.removeFromHistory(items)
            default:
                ()
            }
        }
        
        private func filterItems<T>(_ items: [T]) -> [T] {
            guard presentation.type == .mediaHighlight || presentation.type == .showHighlight else { return items }
            
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
            case .radioShowAccess:
                return NSLocalizedString("Shows", comment: "Title label used to present the radio shows AZ and radio shows by date access buttons")
            case .radioWatchLater, .watchLater:
                return NSLocalizedString("Later", comment: "Title Label used to present the audio later list")
            case .tvLive:
                return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
            case .tvLiveCenter:
                return NSLocalizedString("Sport", comment: "Title label used to present live center medias")
            case .tvScheduledLivestreams:
                return NSLocalizedString("Events", comment: "Title label used to present scheduled livestream medias")
            case .show, .radioEpisodesForDay, .tvEpisodesForDay:
                return nil
            }
        }
        
        var summary: String? {
            return nil
        }
        
        var label: String? {
            return nil
        }
        
        var placeholderItems: [Content.Item] {
            switch configuredSection {
            case .show, .history, .watchLater, .radioEpisodesForDay, .radioLatest, .radioLatestEpisodes, .radioLatestVideos, .radioMostPopular, .tvEpisodesForDay, .tvLiveCenter, .tvScheduledLivestreams:
                return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .tvLive, .radioLive, .radioLiveSatellite:
                return (0..<defaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .favoriteShows, .radioAllShows, .tvAllShows:
                return (0..<defaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
            case .radioFavoriteShows, .radioLatestEpisodesFromFavorites, .radioResumePlayback, .radioShowAccess, .radioWatchLater:
                return []
            }
        }
        
        var displaysTitle: Bool {
            return true
        }
        
        var supportsEdition: Bool {
            switch configuredSection {
            case .favoriteShows, .history, .radioFavoriteShows, .radioResumePlayback, .radioWatchLater, .watchLater:
                return true
            default:
                return false
            }
        }
        
        var emptyType: Content.EmptyType {
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
            default:
                return .generic
            }
        }
        
        var imageType: SRGImageType {
            guard ApplicationConfiguration.shared.arePosterImagesEnabled else { return .default }
            switch configuredSection {
            case .tvAllShows:
                return .showPoster
            default:
                return .default
            }
        }
        
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
            case .radioEpisodesForDay, .radioLive, .radioLiveSatellite, .radioShowAccess, .tvEpisodesForDay, .tvLive:
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
            case .radioEpisodesForDay, .radioLive, .radioLiveSatellite, .radioShowAccess, .tvEpisodesForDay, .tvLive:
                return nil
            case .favoriteShows, .history, .watchLater:
                return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.user.rawValue]
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
            case let .radioShowAccess(channelUid):
                #if os(iOS)
                return Just([.showAccess(radioChannel: configuration.radioChannel(forUid: channelUid))])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                #else
                return Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                #endif
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
                return ThrottledSignal.settingUpdates(at: \.PlaySRGSettingSelectedLivestreamURNForChannels)
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
            default:
                ()
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
    
    static func removeFromWatchLater(_ items: [Content.Item]) {
        let medias = Content.medias(from: items)
        WatchLaterRemoveMedias(medias) { _ in }
    }
    
    static func removeFromHistory(_ items: [Content.Item]) {
        let medias = Content.medias(from: items)
        HistoryRemoveMedias(medias) { _ in }
    }
}
