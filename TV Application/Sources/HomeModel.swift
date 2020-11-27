//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class HomeModel: Identifiable, ObservableObject {
    enum Id {
        case video
        case audio(channel: RadioChannel)
        case live
    }
    
    static let numberOfPlaceholders = 10
    
    let id: Id
    let rowIds: [RowId]
    
    private var eventRowIds: [RowId] = []
    private var topicRowIds: [RowId] = []
    
    typealias Row = CollectionRow<RowId, RowItem>
    
    @Published private(set) var rows = [Row]()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(id: Id) {
        self.id = id
        self.rowIds = Self.rowIds(for: id)
    }
    
    func refresh() {
        cancellables = []
        
        synchronizeRows()
        loadRows()
        
        loadModules(with: .event)
        loadTopics()
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private static func rowIds(for id: Id) -> [RowId] {
        switch id {
        case .video:
            return ApplicationConfiguration.shared.videoHomeRowIds()
        case let .audio(channel):
            return channel.homeRowIds()
        case .live:
            return ApplicationConfiguration.shared.liveHomeRowIds()
        }
    }
    
    private func addRow(with id: RowId, to rows: inout [Row]) {
        if let existingRow = self.rows.first(where: { $0.section == id }) {
            rows.append(existingRow)
        }
        else {
            func items(for id: RowId) -> [RowItem] {
                switch id {
                case .tvTopicsAccess:
                    return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: id, content: .topicPlaceholder(index: $0)) }
                case .radioAllShows:
                    return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: id, content: .showPlaceholder(index: $0)) }
                default:
                    return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: id, content: .mediaPlaceholder(index: $0)) }
                }
            }
            rows.append(Row(section: id, items: items(for: id)))
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
        rows = updatedRows
    }
    
    private func updateRow(with id: RowId, items: [RowItem]) {
        guard items.count != 0,
              let index = rows.firstIndex(where: { $0.section == id }) else { return }
        rows[index] = Row(section: id, items: items)
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
                .store(in: &cancellables)
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
            .store(in: &cancellables)
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
            .store(in: &cancellables)
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
        case tvMostPopular
        case tvSoonExpiring
        case tvLatestForModule(_ module: SRGModule?, type: SRGModuleType)
        case tvLatestForTopic(_ topic: SRGTopic?)
        case tvTopicsAccess
        
        case radioLatestEpisodes(channelUid: String)
        case radioMostPopular(channelUid: String)
        case radioLatest(channelUid: String)
        case radioLatestVideos(channelUid: String)
        case radioAllShows(channelUid: String)
        
        case tvLive
        case radioLive
        case radioLiveSatellite
        
        case tvLiveCenter
        case tvScheduledLivestreams
        
        static var liveIds: [RowId] {
            return [.tvLive, .radioLive, .radioLiveSatellite, .tvLiveCenter, .tvScheduledLivestreams]
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
                return SRGDataProvider.current!.tvTopics(for: vendor)
                    .map { $0.topics.map { RowItem(rowId: self, content: .topic($0)) } }
                    .eraseToAnyPublisher()
            case let .tvLatestForTopic(topic):
                guard let urn = topic?.urn else { return nil }
                return dataProvider.latestMediasForTopic(withUrn: urn, pageSize: pageSize)
                    .map { $0.medias.map { RowItem(rowId: self, content: .media($0)) } }
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
                return SRGDataProvider.current!.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize)
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
        
        var title: String? {
            switch self {
            case let .tvTrending(appearance: appearance):
                return appearance != .hero ? NSLocalizedString("Trending videos", comment: "Title label used to present trending TV videos") : nil
            case .tvLatest:
                return NSLocalizedString("Latest videos", comment: "Title label used to present the latest videos")
            case .tvMostPopular:
                return NSLocalizedString("Most popular", comment: "Title label used to present the TV most popular videos")
            case .tvSoonExpiring:
                return NSLocalizedString("Available for a limited time", comment: "Title label used to present the soon expiring videos")
            case let .tvLatestForModule(module, _):
                return module?.title ?? NSLocalizedString("Highlights", comment: "Title label used to present TV modules while loading. It appears if no network connection is available and no cache is available")
            case let .tvLatestForTopic(topic):
                return topic?.title ?? NSLocalizedString("Topics", comment: "Title label used to present TV topics while loading. It appears if no network connection is available and no cache is available")
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
                return NSLocalizedString("Thematic radios", comment: "Title label to present Swiss satellite radios")
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
        
        static func == (lhs: RowItem, rhs: RowItem) -> Bool {
            return lhs.rowId == rhs.rowId && lhs.content == rhs.content
        }
    }
}
