//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Collections
import SRGDataProviderCombine
import SRGUserData

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
    
    #if os(iOS)
    var sharingItem: SharingItem? { get }
    #endif
    
    /// Publisher providing content for the section. A single result must be delivered upon subscription. Further
    /// results can be retrieved (if any) using a paginator, one page at a time.
    func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error>
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
                    return dataProvider.historyPublisher(pageSize: pageSize, paginatedBy: paginator, filter: filter)
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
            switch configuredSection.type {
            case .radioLatestEpisodes:
                return NSLocalizedString("The latest episodes", comment: "Title label used to present the radio latest audio episodes")
            case .radioMostPopular:
                return NSLocalizedString("Most listened to", comment: "Title label used to present the radio most popular audio medias")
            case .radioLatest:
                return NSLocalizedString("The latest audios", comment: "Title label used to present the radio latest audios")
            case .radioLatestVideos:
                return NSLocalizedString("Latest videos", comment: "Title label used to present the radio latest videos")
            case .radioAllShows:
                return NSLocalizedString("Shows", comment: "Title label used to present radio associated shows")
            case .radioFavoriteShows:
                return NSLocalizedString("Favorites", comment: "Title label used to present the radio favorite shows")
            case .radioShowAccess:
                return NSLocalizedString("Shows", comment: "Title label used to present the radio shows AZ and radio shows by date access buttons")
            case .tvLive:
                return NSLocalizedString("TV channels", comment: "Title label to present main TV livestreams")
            case .radioLive:
                return NSLocalizedString("Radio channels", comment: "Title label to present main radio livestreams")
            case .radioLiveSatellite:
                return NSLocalizedString("Music radios", comment: "Title label to present musical Swiss satellite radios")
            case .tvLiveCenter:
                return NSLocalizedString("Sport", comment: "Title label used to present live center medias")
            case .tvScheduledLivestreams:
                return NSLocalizedString("Events", comment: "Title label used to present scheduled livestream medias")
            }
        }
        
        var summary: String? {
            return nil
        }
        
        var label: String? {
            return nil
        }
        
        var placeholderItems: [Content.Item] {
            switch configuredSection.type {
            case .tvLiveCenter, .tvScheduledLivestreams, .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
                return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .tvLive, .radioLive, .radioLiveSatellite:
                return (0..<defaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
            case .radioAllShows:
                return (0..<defaultNumberOfPlaceholders).map { .showPlaceholder(index: $0) }
            case .radioFavoriteShows, .radioShowAccess:
                return []
            }
        }
        
        var displaysTitle: Bool {
            return true
        }
        
        #if os(iOS)
        var sharingItem: SharingItem? {
            return nil
        }
        #endif
        
        func publisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error> {
            let dataProvider = SRGDataProvider.current!
            
            let configuration = ApplicationConfiguration.shared
            let vendor = configuration.vendor
            
            switch configuredSection.type {
            case let .radioLatestEpisodes(channelUid: channelUid):
                return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioMostPopular(channelUid: channelUid):
                return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatest(channelUid: channelUid):
                return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioLatestVideos(channelUid: channelUid):
                return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize, paginatedBy: paginator)
                    .map { $0.map { .media($0) } }
                    .eraseToAnyPublisher()
            case let .radioAllShows(channelUid):
                return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize, paginatedBy: paginator)
                    .map { $0.map { .show($0) } }
                    .eraseToAnyPublisher()
            case .radioFavoriteShows:
                return dataProvider.favoritesPublisher(filter: filter)
                    .map { $0.map { .show($0) } }
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
            case .tvLive:
                return dataProvider.tvLivestreams(for: vendor)
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
    }
}

// MARK: Publishers

private extension SRGDataProvider {
    /// Publishes the latest 30 episodes for a show URN list.
    func latestMediasForShowsPublisher(withUrns urns: [String], pageSize: UInt) -> AnyPublisher<[SRGMedia], Error> {
        return urns.publisher
            .collect(3)
            .flatMap { urns in
                return self.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
            }
            .reduce([]) { $0 + $1 }
            .map { medias in
                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(Int(pageSize)))
            }
            .eraseToAnyPublisher()
    }
    
    #if os(iOS)
    /// Publishes the regional media which corresponds to the specified media, if any.
    private func regionalizeRadioLivestreamMedia(for media: SRGMedia) -> AnyPublisher<SRGMedia, Never> {
        if let channelUid = media.channel?.uid,
           let selectedLivestreamUrn = ApplicationSettingSelectedLivestreamURNForChannelUid(channelUid),
           media.urn != selectedLivestreamUrn {
            return radioLivestreams(for: media.vendor, channelUid: channelUid)
                .map { medias in
                    if let selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(channelUid, medias) {
                        return selectedMedia
                    }
                    else {
                        return media
                    }
                }
                .replaceError(with: media)
                .eraseToAnyPublisher()
        }
        else {
            return Just(media)
                .eraseToAnyPublisher()
        }
    }
    #endif
    
    /// Publishes radio livestreams, replacing regional radio channels. Updates are published down the pipeline as they
    /// are retrieved.
    func regionalizedRadioLivestreams(for vendor: SRGVendor, contentProviders: SRGContentProviders = .default) -> AnyPublisher<[SRGMedia], Error> {
        #if os(iOS)
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .map { medias in
                return Publishers.AccumulateLatestMany(medias.map { media in
                    return self.regionalizeRadioLivestreamMedia(for: media)
                })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
        #else
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .eraseToAnyPublisher()
        #endif
    }
    
    func historyPublisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[SRGMedia], Error> {
        func playbackPositions(for historyEntries: [SRGHistoryEntry]?) -> OrderedDictionary<String, TimeInterval> {
            guard let historyEntries = historyEntries else { return [:] }
            
            var playbackPositions = OrderedDictionary<String, TimeInterval>()
            for historyEntry in historyEntries {
                if let uid = historyEntry.uid {
                    playbackPositions[uid] = CMTimeGetSeconds(historyEntry.lastPlaybackTime)
                }
            }
            return playbackPositions
        }
        
        // Use a deferred future to make it repeatable on-demand
        // See https://heckj.github.io/swiftui-notes/#reference-future
        return Deferred {
            Future<OrderedDictionary<String, TimeInterval>, Error> { promise in
                let sortDescriptor = NSSortDescriptor(keyPath: \SRGHistoryEntry.date, ascending: false)
                SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(playbackPositions(for: historyEntries)))
                    }
                }
            }
        }
        .map { playbackPositions in
            return self.medias(withUrns: Array(playbackPositions.keys), pageSize: pageSize, paginatedBy: paginator)
                .map { medias in
                    return filter?.compatibleMedias(medias) ?? medias
                }
                .map {
                    return $0.filter { media in
                        guard let playbackPosition = playbackPositions[media.urn] else { return true }
                        return HistoryCanResumePlaybackForMediaMetadataAndPosition(playbackPosition, media)
                    }
                }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    func laterPublisher(pageSize: UInt, paginatedBy paginator: Trigger.Signal?, filter: SectionFiltering?) -> AnyPublisher<[SRGMedia], Error> {
        // Use a deferred future to make it repeatable on-demand
        // See https://heckj.github.io/swiftui-notes/#reference-future
        return Deferred {
            Future<[String], Error> { promise in
                let sortDescriptor = NSSortDescriptor(keyPath: \SRGPlaylistEntry.date, ascending: false)
                SRGUserData.current!.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: [sortDescriptor]) { playlistEntries, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    else {
                        promise(.success(playlistEntries?.compactMap(\.uid) ?? []))
                    }
                }
            }
        }
        .map { urns in
            return self.medias(withUrns: urns, pageSize: pageSize, paginatedBy: paginator)
                .map { medias in
                    return filter?.compatibleMedias(medias) ?? medias
                }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let trigger = Trigger()
        
        return shows(withUrns: urns, pageSize: 50 /* Use largest page size */, paginatedBy: trigger.signal(activatedBy: 1))
            .handleEvents(receiveOutput: { _ in
                // FIXME: There is probably a better way
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    trigger.activate(for: 1)
                }
            })
            .reduce([]) { $0 + $1 }
            .map { $0.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } }
            .eraseToAnyPublisher()
    }
    
    func favoritesPublisher(filter: SectionFiltering?) -> AnyPublisher<[SRGShow], Error> {
        // For some reason (compiler bug?) the type of the items is seen as [Any] and requires casting
        return self.showsPublisher(withUrns: FavoritesShowURNs().array as? [String] ?? [])
            .map { filter?.compatibleShows($0) ?? $0 }
            .eraseToAnyPublisher()
    }
}
