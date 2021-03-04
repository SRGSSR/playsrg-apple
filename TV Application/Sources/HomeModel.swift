//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

class HomeModel: Identifiable, ObservableObject {
    enum Id {
        case video
        case audio(channel: RadioChannel)
        case live
        
        var defaultRowIds: [RowId] {
            switch self {
            case .video:
                return ApplicationConfiguration.shared.videoHomeRowIds()
            case let .audio(channel):
                return channel.homeRowIds()
            case .live:
                return ApplicationConfiguration.shared.liveHomeRowIds()
            }
        }
    }
    
    let id: Id
    let rowIds: [RowId]
    
    private var eventRowIds: [RowId] = []
    private var topicRowIds: [RowId] = []
    
    typealias Row = CollectionRow<RowId, RowItem>
    
    // Store all rows so that row updates always find a matching row. Only return non-empty ones, publicly though
    private var loadedRows: [Row] = [] {
        didSet {
            rows = loadedRows.filter { !$0.items.isEmpty }
        }
    }
    
    @Published private(set) var rows: [Row] = []
    
    private var mainCancellables = Set<AnyCancellable>()
    private var refreshCancellables = Set<AnyCancellable>()
    
    init(id: Id) {
        self.id = id
        self.rowIds = id.defaultRowIds
            
        if self.rowIds.contains(where: { $0.isFavoriteShows }) {
            NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
                .sink { notification in
                    guard let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) else { return }
                    self.refresh()
                }
                .store(in: &mainCancellables)
        }
        
        if self.rowIds.contains(.tvResumePlayback) {
            NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
                .sink { _ in
                    self.refresh()
                }
                .store(in: &mainCancellables)
        }
        
        if self.rowIds.contains(.tvWatchLater) {
            NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistsDidChange, object: SRGUserData.current?.playlists)
                .sink { notification in
                    guard let playlistUids = notification.userInfo?[SRGPlaylistsUidsKey] as? Set<String>, playlistUids.contains(SRGPlaylistUid.watchLater.rawValue) else { return }
                    self.refresh()
                }
                .store(in: &mainCancellables)
        }
    }
    
    func refresh() {
        refreshCancellables = []
        
        synchronizeRows()
        loadRows()
        
        loadModules(with: .event)
        loadTopics()
    }
    
    func cancelRefresh() {
        refreshCancellables = []
    }
    
    private func addRow(with id: RowId, to rows: inout [Row]) {
        if let existingRow = loadedRows.first(where: { $0.section == id }), !existingRow.items.isEmpty {
            rows.append(existingRow)
        }
        else {
            rows.append(Row(section: id, items: id.placeholderItems))
        }
    }
    
    private func addRows(with ids: [RowId], to rows: inout [Row]) {
        for id in ids {
            addRow(with: id, to: &rows)
        }
    }
    
    private func synchronizeRows() {
        var updatedRows = [Row]()
        for id in rowIds {
            if case let .tvLatestForModule(_, type: type) = id, type == .event {
                addRows(with: eventRowIds, to: &updatedRows)
            }
            else if case .tvLatestForTopic = id {
                addRows(with: topicRowIds, to: &updatedRows)
            }
            else {
                addRow(with: id, to: &updatedRows)
            }
        }
        loadedRows = updatedRows
    }
    
    private func updateRow(with id: RowId, items: [RowItem]) {
        guard let index = loadedRows.firstIndex(where: { $0.section == id }) else { return }
        loadedRows[index] = Row(section: id, items: items)
    }
    
    private func loadRows(with ids: [RowId]? = nil) {
        let reloadedRowIds = ids ?? rowIds
        for rowId in reloadedRowIds {
            rowId.publisher()?
                .replaceError(with: [])
                .receive(on: DispatchQueue.main)
                .sink { items in
                    self.updateRow(with: rowId, items: items)
                }
                .store(in: &refreshCancellables)
        }
    }
    
    private func loadModules(with type: SRGModuleType) {
        guard rowIds.contains(.tvLatestForModule(nil, type: type)) else { return }
        
        SRGDataProvider.current!.modules(for: ApplicationConfiguration.shared.vendor, type: type)
            .map { result in
                result.modules.map { RowId.tvLatestForModule($0, type: type) }
            }
            .replaceError(with: eventRowIds)
            .receive(on: DispatchQueue.main)
            .sink { rowIds in
                self.eventRowIds = rowIds
                self.synchronizeRows()
                self.loadRows(with: rowIds)
            }
            .store(in: &refreshCancellables)
    }
    
    private func loadTopics() {
        guard rowIds.contains(.tvLatestForTopic(nil)) else { return }
        
        SRGDataProvider.current!.tvTopics(for: ApplicationConfiguration.shared.vendor)
            .map { result in
                result.topics.map { RowId.tvLatestForTopic($0) }
            }
            .replaceError(with: topicRowIds)
            .receive(on: DispatchQueue.main)
            .sink { rowIds in
                self.topicRowIds = rowIds
                self.synchronizeRows()
                self.loadRows(with: rowIds)
            }
            .store(in: &refreshCancellables)
    }
}

extension HomeModel {
    enum RowAppearance: Equatable {
        case `default`
        case hero
    }

    enum RowId: Hashable {
        case tvTrending(appearance: RowAppearance)
        case tvLatest
        case tvFavoriteShows
        case tvFavoriteLatestEpisodes
        case tvWebFirst
        case tvMostPopular
        case tvSoonExpiring
        case tvLatestForModule(_ module: SRGModule?, type: SRGModuleType)
        case tvLatestForTopic(_ topic: SRGTopic?)
        case tvTopicsAccess
        case tvResumePlayback
        case tvWatchLater
        
        case radioLatestEpisodes(channelUid: String)
        case radioMostPopular(channelUid: String)
        case radioLatest(channelUid: String)
        case radioLatestVideos(channelUid: String)
        case radioAllShows(channelUid: String)
        case radioFavoriteShows(channelUid: String)
        
        case tvLive
        case radioLive
        case radioLiveSatellite
        
        case tvLiveCenter
        case tvScheduledLivestreams
        
        static let numberOfPlaceholders = 10
        
        var isLive: Bool {
            switch self {
            case .tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams:
                return true
            default:
                return false
            }
        }
        
        var isFavoriteShows: Bool {
            switch self {
            case .tvFavoriteShows, .tvFavoriteLatestEpisodes, .radioFavoriteShows:
                return true
            default:
                return false
            }
        }
        
        var placeholderItems: [RowItem] {
            switch self {
            case .tvTopicsAccess:
                return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: self, content: .topicPlaceholder(index: $0)) }
            case .tvFavoriteShows, .tvFavoriteLatestEpisodes, .radioFavoriteShows, .tvResumePlayback, .tvWatchLater:
                return []
            case .radioAllShows:
                return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: self, content: .showPlaceholder(index: $0)) }
            default:
                return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: self, content: .mediaPlaceholder(index: $0)) }
            }
        }
                
        func publisher() -> AnyPublisher<[RowItem], Error>? {
            let dataProvider = SRGDataProvider.current!
            let configuration = ApplicationConfiguration.shared
            
            let vendor = configuration.vendor
            let pageSize = configuration.pageSize
            
            switch self {
            case .tvTrending:
                if configuration.tvTrendingPrefersHeroStage {
                    return dataProvider.tvHeroStageMedias(for: vendor)
                        .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                        .eraseToAnyPublisher()
                }
                else {
                    return dataProvider.tvTrendingMedias(for: vendor, limit: pageSize, editorialLimit: configuration.tvTrendingEditorialLimit?.uintValue,
                                                         episodesOnly: configuration.tvTrendingEpisodesOnly)
                        .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                        .eraseToAnyPublisher()
                }
            case .tvLatest:
                return dataProvider.tvLatestMedias(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvFavoriteShows, .radioFavoriteShows:
                return showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { compatibleShows($0).map { RowItem(rowId: self, content: .show($0)) } }
                    .eraseToAnyPublisher()
            case .tvFavoriteLatestEpisodes:
                return showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { compatibleShows($0).map { $0.urn } }
                    .flatMap { urns in
                        return latestMediasForShowsPublisher(withUrns: urns)
                    }
                    .map { $0.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvWebFirst:
                return dataProvider.tvLatestWebFirstEpisodes(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvMostPopular:
                return dataProvider.tvMostPopularMedias(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvSoonExpiring:
                return dataProvider.tvSoonExpiringMedias(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .tvLatestForModule(module, type: _):
                guard let urn = module?.urn else { return nil }
                return dataProvider.latestMediasForModule(withUrn: urn, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvTopicsAccess:
                return dataProvider.tvTopics(for: vendor)
                    .map { $0.topics.map { RowItem(rowId: self, content: .topic($0)) } }
                    .eraseToAnyPublisher()
            case let .tvLatestForTopic(topic):
                guard let urn = topic?.urn else { return nil }
                return dataProvider.latestMediasForTopic(withUrn: urn, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvResumePlayback:
                return historyPublisher()
                    .map { compatibleMedias($0).prefix(Int(pageSize)).map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvWatchLater:
                return laterPublisher()
                    .map { compatibleMedias($0).prefix(Int(pageSize)).map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioLatestEpisodes(channelUid: channelUid):
                return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioMostPopular(channelUid: channelUid):
                return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioLatest(channelUid: channelUid):
                return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioLatestVideos(channelUid: channelUid):
                return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioAllShows(channelUid):
                return dataProvider.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize)
                    .map { $0.shows.map { RowItem(rowId: self, content: .show($0)) } }
                    .eraseToAnyPublisher()
            case .tvLive:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .radioLive:
                return dataProvider.radioLivestreams(for: vendor, contentProviders: .default)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .radioLiveSatellite:
                return dataProvider.radioLivestreams(for: vendor, contentProviders: .swissSatelliteRadio)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenter:
                return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreams:
                return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            }
        }
        
        private func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
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
        
        private func latestMediasForShowsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGMedia], Error> {
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
        
        private func historyPublisher() -> AnyPublisher<[SRGMedia], Error> {
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
        
        private func laterPublisher() -> AnyPublisher<[SRGMedia], Error> {
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
        
        private func canContain(show: SRGShow) -> Bool {
            switch self {
            case .tvFavoriteShows, .tvFavoriteLatestEpisodes:
                return show.transmission == .TV
            case let .radioFavoriteShows(channelUid: channelUid):
                return show.transmission == .radio && show.primaryChannelUid == channelUid
            default:
                return false
            }
        }
        
        private func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
            return shows.filter { self.canContain(show: $0) }.sorted(by: { $0.title < $1.title })
        }
        
        private func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
            return medias.filter { $0.mediaType == .video }
        }
        
        var title: String? {
            switch self {
            case let .tvTrending(appearance: appearance):
                return appearance != .hero ? NSLocalizedString("Trending videos", comment: "Title label used to present trending TV videos") : nil
            case .tvLatest:
                return NSLocalizedString("Latest videos", comment: "Title label used to present the latest videos")
            case .tvWebFirst:
                return NSLocalizedString("Already available", comment: "Title label used to present already available videos, usually badged as web first")
            case .tvMostPopular:
                return NSLocalizedString("Most popular", comment: "Title label used to present the TV most popular videos")
            case .tvSoonExpiring:
                return NSLocalizedString("Available for a limited time", comment: "Title label used to present the soon expiring videos")
            case let .tvLatestForModule(module, _):
                return module?.title ?? NSLocalizedString("Highlights", comment: "Title label used to present TV modules while loading. It appears if no network connection is available and no cache is available")
            case let .tvLatestForTopic(topic):
                return topic?.title ?? NSLocalizedString("Topics", comment: "Title label used to present TV topics while loading. It appears if no network connection is available and no cache is available")
            case .tvFavoriteShows, .radioFavoriteShows:
                return NSLocalizedString("Favorites", comment: "Title label used to present the TV or radio favorite shows")
            case .tvFavoriteLatestEpisodes:
                return NSLocalizedString("Latest episodes from your favorites", comment: "Title label used to present the latest episodes from TV favorite shows")
            case .tvResumePlayback:
                return NSLocalizedString("Resume playback", comment: "Title label used to present medias whose playback can be resumed")
            case .tvWatchLater:
                return NSLocalizedString("Later", comment: "Title Label used to present the video later list")
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
            default:
                return nil
            }
        }
        
        var lead: String? {
            if case let .tvLatestForModule(module, type: _) = self {
                return module?.lead
            }
            else {
                return nil
            }
        }
    }
}

extension HomeModel {
    struct RowItem: Hashable {
        // Various kinds of objects which can be displayed on the home.
        enum Content: Hashable {
            case mediaPlaceholder(index: Int)
            case media(_ media: SRGMedia)
            
            case showPlaceholder(index: Int)
            case show(_ show: SRGShow)
            
            case topicPlaceholder(index: Int)
            case topic(_ topic: SRGTopic)
        }
        
        // Some items might appear in several rows but need to be uniquely defined. We thus add the section to each item
        // to ensure unicity.
        let rowId: RowId
        let content: Content
    }
}
