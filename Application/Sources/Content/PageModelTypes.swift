//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel
import SRGUserData

fileprivate let defaultNumberOfPlaceholders = 10

protocol PageSectionProperties {
    var title: String? { get }
    var summary: String? { get }
    var presentationType: SRGContentPresentationType { get }
    var layout: PageModel.SectionLayout { get }
    
    func placeholderItems(for section: PageModel.Section) -> [PageModel.Item]
    func publisher(for id: PageModel.Id, section: PageModel.Section) -> AnyPublisher<[PageModel.Item], Error>?
}

extension PageModel {
    // TODO: Naming? e.g. serviced vs configured, content vs play, remote vs application, etc.
    enum Section: Hashable {
        case content(SRGContentSection)
        case play(ConfiguredSection)
        
        var properties: PageSectionProperties {
            switch self {
            case let .content(section):
                return section
            case let .play(section):
                return section
            }
        }
    }
    
    enum SectionLayout: Hashable {
        case hero
        case highlight
        case topicSelector
        case shows
        case medias
        #if os(iOS)
        case showAccess
        #endif
    }
    
    // On a page items must be unique per section, which is why a section parameter must be provided for each of them.
    enum Item: Hashable {
        case mediaPlaceholder(index: Int, section: Section)
        case media(_ media: SRGMedia, section: Section)
        
        case showPlaceholder(index: Int, section: Section)
        case show(_ show: SRGShow, section: Section)
        
        case topicPlaceholder(index: Int, section: Section)
        case topic(_ topic: SRGTopic, section: Section)
        
        #if os(iOS)
        case showAccess(radioChannel: RadioChannel?, section: Section)
        #endif
    }
}

extension SRGContentSection: PageSectionProperties {
    var title: String? {
        if type == .predefined {
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
            case .none, .topicSelector, .swimlane, .hero, .grid, .mediaHighlight, .showHighlight:
                return nil
            }
        }
        else {
            return presentation.title
        }
    }
    
    var summary: String? {
        return presentation.summary
    }
    
    var presentationType: SRGContentPresentationType {
        return presentation.type
    }
    
    var layout: PageModel.SectionLayout {
        switch presentation.type {
        case .hero:
            return .hero
        case .mediaHighlight, .showHighlight:
            return .highlight
        case .topicSelector:
            return .topicSelector
        case .showAccess:
            #if os(iOS)
            return .showAccess
            #else
            // Not supported
            return .medias
            #endif
        case .favoriteShows:
            return .shows
        case .swimlane, .grid:
            return (type == .shows) ? .shows : .medias
        case .none, .livestreams, .resumePlayback, .watchLater, .personalizedProgram:
            return .medias
        }
    }
    
    func placeholderItems(for section: PageModel.Section) -> [PageModel.Item] {
        switch presentation.type {
        case .mediaHighlight:
            return [.mediaPlaceholder(index: 0, section: section)]
        case .showHighlight:
            return [.showPlaceholder(index: 0, section: section)]
        case .topicSelector:
            return (0..<defaultNumberOfPlaceholders).map { .topicPlaceholder(index: $0, section: section) }
        case .swimlane, .hero, .grid, .livestreams:
            return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0, section: section) }
        case .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram, .none, .showAccess:
            return []
        }
    }
    
    func publisher(for id: PageModel.Id, section: PageModel.Section) -> AnyPublisher<[PageModel.Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        switch type {
        case .medias:
            return dataProvider.medias(for: vendor, contentSectionUid: uid, pageSize: pageSize)
                .map { self.filterItems($0.medias).map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .showAndMedias:
            return dataProvider.showAndMedias(for: vendor, contentSectionUid: uid, pageSize: pageSize)
                .map {
                    var items = [PageModel.Item]()
                    if let show = $0.showAndMedias.show {
                        items.append(.show(show, section: section))
                    }
                    items.append(contentsOf: $0.showAndMedias.medias.map { .media($0, section: section) })
                    return items
                }
                .eraseToAnyPublisher()
        case .shows:
            return dataProvider.shows(for: vendor, contentSectionUid: uid, pageSize: pageSize)
                .map { self.filterItems($0.shows).map { .show($0, section: section) } }
                .eraseToAnyPublisher()
        case .predefined:
            switch presentation.type {
            case .favoriteShows:
                return PageSectionPublisher.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { id.compatibleShows($0).map { .show($0, section: section) } }
                    .eraseToAnyPublisher()
            case .personalizedProgram:
                return PageSectionPublisher.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { id.compatibleShows($0).map { $0.urn } }
                    .flatMap { urns in
                        return PageSectionPublisher.latestMediasForShowsPublisher(withUrns: urns)
                    }
                    .map { $0.map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .livestreams:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.medias.map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .topicSelector:
                return dataProvider.tvTopics(for: vendor)
                    .map { $0.topics.map { .topic($0, section: section) } }
                    .eraseToAnyPublisher()
            case .resumePlayback:
                return PageSectionPublisher.historyPublisher()
                    .map { id.compatibleMedias($0).prefix(Int(pageSize)).map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .watchLater:
                return PageSectionPublisher.laterPublisher()
                    .map { id.compatibleMedias($0).prefix(Int(pageSize)).map { .media($0, section: section) } }
                    .eraseToAnyPublisher()
            case .showAccess:
                #if os(iOS)
                return Just([.showAccess(radioChannel: nil, section: section)])
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

extension ConfiguredSection: PageSectionProperties {
    var title: String? {
        switch self.type {
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
    
    var presentationType: SRGContentPresentationType {
        return self.contentPresentationType
    }
    
    var layout: PageModel.SectionLayout {
        switch self.type {
        case .tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams, .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
            return (self.contentPresentationType == .hero) ? .hero : .medias
        case .radioAllShows, .radioFavoriteShows:
            return .shows
        case .radioShowAccess:
            #if os(iOS)
            return .showAccess
            #else
            // Not supported
            return .medias
            #endif
        }
    }
    
    func placeholderItems(for section: PageModel.Section) -> [PageModel.Item] {
        switch self.type {
        case .tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams, .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
            return (0..<defaultNumberOfPlaceholders).map { .mediaPlaceholder(index: $0, section: section) }
        case .radioAllShows:
            return (0..<defaultNumberOfPlaceholders).map { .showPlaceholder(index: $0, section: section) }
        case .radioFavoriteShows, .radioShowAccess:
            return []
        }
    }
    
    func publisher(for id: PageModel.Id, section: PageModel.Section) -> AnyPublisher<[PageModel.Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        switch self.type {
        case let .radioLatestEpisodes(channelUid: channelUid):
            return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioMostPopular(channelUid: channelUid):
            return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioLatest(channelUid: channelUid):
            return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioLatestVideos(channelUid: channelUid):
            return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioAllShows(channelUid):
            return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize)
                .map { $0.shows.map { .show($0, section: section) } }
                .eraseToAnyPublisher()
        case .radioFavoriteShows:
            return PageSectionPublisher.showsPublisher(withUrns: Array(FavoritesShowURNs()))
                .map { id.compatibleShows($0).map { .show($0, section: section) } }
                .eraseToAnyPublisher()
        case let .radioShowAccess(channelUid):
            #if os(iOS)
            return Just([.showAccess(radioChannel: configuration.radioChannel(forUid: channelUid), section: section)])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            #else
            return nil
            #endif
        case .tvLive:
            return dataProvider.tvLivestreams(for: vendor)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .radioLive:
            return dataProvider.radioLivestreams(for: vendor, contentProviders: .default)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .radioLiveSatellite:
            return dataProvider.radioLivestreams(for: vendor, contentProviders: .swissSatelliteRadio)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .tvLiveCenter:
            return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        case .tvScheduledLivestreams:
            return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize)
                .map { $0.medias.map { .media($0, section: section) } }
                .eraseToAnyPublisher()
        }
    }
}

fileprivate struct PageSectionPublisher {
    static func latestMediasForShowsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGMedia], Error> {
        /* Load latest 15 medias for each 3 shows, get last 30 episodes */
        return urns.publisher
            .collect(3)
            .flatMap { urns in
                return SRGDataProvider.current!.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
            }
            .reduce([SRGMedia]()) { collectedMedias, result in
                return collectedMedias + result.medias
            }
            .map { medias in
                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(30))
            }
            .eraseToAnyPublisher()
    }
    
    static func historyPublisher() -> AnyPublisher<[SRGMedia], Error> {
        // TODO: Currently suboptimal: For each media we determine if playback can be resumed, an operation on
        //       the main thread and with a single user data access each time. We could  instead use a currrently
        //       private history API to combine the history entries we have and the associated medias we retrieve
        //       with a network request, calculating the progress on a background thread and with only a single
        //       user data access (the one made at the beginning). This optimization seems premature, though, so
        //       for the moment a simpler implementation is used.
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
        .map { historyEntries in
            historyEntries.compactMap { $0.uid }
        }
        .flatMap { urns in
            return SRGDataProvider.current!.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
        }
        .receive(on: DispatchQueue.main)
        .map { $0.medias.filter { HistoryCanResumePlaybackForMedia($0) } }
        .eraseToAnyPublisher()
    }
    
    static func laterPublisher() -> AnyPublisher<[SRGMedia], Error> {
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
        .map { playlistEntries in
            playlistEntries.compactMap { $0.uid }
        }
        .flatMap { urns in
            return SRGDataProvider.current!.medias(withUrns: urns, pageSize: 50 /* Use largest page size */)
        }
        .map { $0.medias }
        .eraseToAnyPublisher()
    }
    
    static func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let dataProvider = SRGDataProvider.current!
        let pagePublisher = CurrentValueSubject<SRGDataProvider.Shows.Page?, Never>(nil)
        
        return pagePublisher
            .flatMap { page in
                return page != nil ? dataProvider.shows(at: page!) : dataProvider.shows(withUrns: urns, pageSize: 50 /* Use largest page size */)
            }
            .handleEvents(receiveOutput: { result in
                if let nextPage = result.nextPage {
                    pagePublisher.value = nextPage
                }
                else {
                    pagePublisher.send(completion: .finished)
                }
            })
            .reduce([SRGShow]()) { collectedShows, result in
                return collectedShows + result.shows
            }
            .eraseToAnyPublisher()
    }
}
