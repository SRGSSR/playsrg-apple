//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

private let defaultNumberOfPlaceholders = 10
private let defaultNumberOfLivestreamPlaceholders = 4

protocol SectionFiltering {
    func compatibleShows(_ shows: [SRGShow]) -> [SRGShow]
    func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia]
}

protocol SectionProperties {
    var title: String? { get }
    var summary: String? { get }
    var label: String? { get }
    var placeholderItems: [PlaySRG.Item] { get }
    
    func publisher(filter: SectionFiltering, triggerId: Trigger.Id) -> AnyPublisher<[Item], Error>?
}

// FIXME: Find less conflicting name or use namespace for Section & Item
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

// Items can appear in several sections, which is why a section parameter must be provided for each of them so
// that each item is truly unique.
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
    
    var placeholderItems: [PlaySRG.Item] {
        switch presentation.type {
        case .mediaHighlight:
            return [.mediaPlaceholder(index: 0)]
        case .showHighlight:
            return [.showPlaceholder(index: 0)]
        case .topicSelector:
            return (0..<defaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0) }
        case .swimlane, .hero, .grid:
            return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0) }
        case .livestreams:
            return (0..<defaultNumberOfLivestreamPlaceholders).map { .mediaPlaceholder(index: $0) }
        case .none, .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram, .showAccess:
            return []
        }
    }
    
    func publisher(filter: SectionFiltering, triggerId: Trigger.Id) -> AnyPublisher<[Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        switch contentSection.type {
        case .medias:
            return dataProvider.medias(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { self.filterItems($0).map { .media($0) } }
                .eraseToAnyPublisher()
        case .showAndMedias:
            return dataProvider.showAndMedias(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, triggerId: triggerId)
                .scan((show: nil as SRGShow?, medias: [SRGMedia]())) {
                    return (show: $0.show, medias: $0.medias + $1.medias)
                }
                .map {
                    var items = [Item]()
                    if let show = $0.show {
                        items.append(.show(show))
                    }
                    items.append(contentsOf: $0.medias.map { .media($0) })
                    return items
                }
                .eraseToAnyPublisher()
        case .shows:
            return dataProvider.shows(for: vendor, contentSectionUid: contentSection.uid, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
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
                    .map { $0.map { $0.urn } }
                    .flatMap { urns in
                        return dataProvider.latestMediasForShowsPublisher(withUrns: urns)
                    }
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
                return dataProvider.historyPublisher()
                    .map { filter.compatibleMedias($0).prefix(Int(pageSize)).map { .media($0) } }
                    .eraseToAnyPublisher()
            case .watchLater:
                return dataProvider.laterPublisher()
                    .map { filter.compatibleMedias($0).prefix(Int(pageSize)).map { .media($0) } }
                    .eraseToAnyPublisher()
            case .showAccess:
                #if os(iOS)
                return Just([.showAccess(radioChannel: nil)])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                #else
                return nil
                #endif
            case .none, .swimlane, .hero, .grid, .mediaHighlight, .showHighlight:
                return nil
            }
        case .none:
            return nil
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
    
    var placeholderItems: [PlaySRG.Item] {
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
    
    func publisher(filter: SectionFiltering, triggerId: Trigger.Id) -> AnyPublisher<[Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        switch configuredSection.type {
        case let .radioLatestEpisodes(channelUid: channelUid):
            return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { $0.map { .media($0) } }
                .eraseToAnyPublisher()
        case let .radioMostPopular(channelUid: channelUid):
            return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { $0.map { .media($0) } }
                .eraseToAnyPublisher()
        case let .radioLatest(channelUid: channelUid):
            return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { $0.map { .media($0) } }
                .eraseToAnyPublisher()
        case let .radioLatestVideos(channelUid: channelUid):
            return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { $0.map { .media($0) } }
                .eraseToAnyPublisher()
        case let .radioAllShows(channelUid):
            return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
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
            return nil
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
            return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { $0.map { .media($0) } }
                .eraseToAnyPublisher()
        case .tvScheduledLivestreams:
            return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize, triggerId: triggerId)
                .scan([]) { $0 + $1 }
                .map { $0.map { .media($0) } }
                .eraseToAnyPublisher()
        }
    }
}

fileprivate extension SRGDataProvider {
    /// Publishes the latest 30 episodes for a show URN list
    func latestMediasForShowsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGMedia], Error> {
        return urns.publisher
            .collect(3)
            .flatMap { urns in
                return self.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
            }
            .reduce([]) { $0 + $1 }
            .map { medias in
                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(30))
            }
            .eraseToAnyPublisher()
    }
    
    /// Publishes radio livestreams, replacing regional radio channels. Updates are published down the pipeline as they
    /// are retrieved.
    func regionalizedRadioLivestreams(for vendor: SRGVendor, contentProviders: SRGContentProviders = .default) -> AnyPublisher<[SRGMedia], Error> {
        #if os(iOS)
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .flatMap { medias -> AnyPublisher<[SRGMedia], Error> in
                var regionalizedMedias = medias
                return Publishers.MergeMany(regionalizedMedias.compactMap { media -> AnyPublisher<[SRGMedia], Error>? in
                    guard let channelUid = media.channel?.uid else { return nil }
                    
                    // If a regional stream has been selected by the user, replace the main channel media with it
                    let selectedLivestreamUrn = ApplicationSettingSelectedLivestreamURNForChannelUid(channelUid)
                    if selectedLivestreamUrn != nil && media.urn != selectedLivestreamUrn {
                        return self.radioLivestreams(for: vendor, channelUid: channelUid)
                            .map { result in
                                if let selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(channelUid, medias) {
                                    guard let index = regionalizedMedias.firstIndex(of: media) else { return regionalizedMedias }
                                    regionalizedMedias[index] = selectedMedia
                                }
                                return regionalizedMedias
                            }
                            .eraseToAnyPublisher()
                    }
                    else {
                        return Just(regionalizedMedias)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                })
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        #else
        return radioLivestreams(for: vendor, contentProviders: contentProviders)
            .eraseToAnyPublisher()
        #endif
    }
    
    func historyPublisher() -> AnyPublisher<[SRGMedia], Error> {
        // Drive updates with notifications, using `prepend(_:)` to trigger an initial update
        // Inpsired from https://stackoverflow.com/questions/66075000/swift-combine-publishers-where-one-hasnt-sent-a-value-yet
        NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .map { _ in }
            .prepend(())
            .flatMap { _ in
                return Future<[SRGHistoryEntry], Error> { promise in
                    let sortDescriptor = NSSortDescriptor(keyPath: \SRGHistoryEntry.date, ascending: false)
                    SRGUserData.current!.history.historyEntries(matching: nil, sortedWith: [sortDescriptor]) { historyEntries, error in
                        if let error = error {
                            promise(.failure(error))
                        }
                        else {
                            promise(.success(historyEntries ?? []))
                        }
                    }
                }
            }
            .map { historyEntries in
                historyEntries.compactMap { $0.uid }
            }
            .flatMap { urns in
                return self.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
            }
            // TODO: Currently suboptimal: For each media we determine if playback can be resumed, an operation on
            //       the main thread and with a single user data access each time. We could  instead use a currrently
            //       private history API to combine the history entries we have and the associated medias we retrieve
            //       with a network request, calculating the progress on a background thread and with only a single
            //       user data access (the one made at the beginning). This optimization seems premature, though, so
            //       for the moment a simpler implementation is used.
            .receive(on: DispatchQueue.main)
            .map { $0.filter { HistoryCanResumePlaybackForMedia($0) } }
            .eraseToAnyPublisher()
    }
    
    func laterPublisher() -> AnyPublisher<[SRGMedia], Error> {
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .drop { notification in
                if let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue {
                    return false
                }
                else {
                    return true
                }
            }
            .map { _ in }
            .prepend(())
            .flatMap { _ in
                return Future<[SRGPlaylistEntry], Error> { promise in
                    let sortDescriptor = NSSortDescriptor(keyPath: \SRGPlaylistEntry.date, ascending: false)
                    SRGUserData.current!.playlists.playlistEntriesInPlaylist(withUid: SRGPlaylistUid.watchLater.rawValue, matching: nil, sortedWith: [sortDescriptor]) { playlistEntries, error in
                        if let error = error {
                            promise(.failure(error))
                        }
                        else {
                            promise(.success(playlistEntries ?? []))
                        }
                    }
                }
            }
            .map { playlistEntries in
                playlistEntries.compactMap { $0.uid }
            }
            .flatMap { urns in
                return self.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
            }
            .eraseToAnyPublisher()
    }
    
    func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let trigger = Trigger()
        
        return shows(withUrns: urns, pageSize: 50 /* Use largest page size */, triggerId: trigger.id(1))
            .handleEvents(receiveOutput: { shows in
                // FIXME: There is probably a better way
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    trigger.signal(1)
                }
            })
            .reduce([]) { $0 + $1 }
            .map { $0.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } }
            .eraseToAnyPublisher()
    }
    
    func favoritesPublisher(filter: SectionFiltering) -> AnyPublisher<[SRGShow], Error> {
        return NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .drop { notification in
                if let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) {
                    return false
                }
                else {
                    return true
                }
            }
            .map { _ in }
            .prepend(())
            .flatMap { _ in
                return self.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { filter.compatibleShows($0) }
            }
            .eraseToAnyPublisher()
    }
}
