//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
/**
 *  The appearance to apply to a home row.
 */
enum HomeRowAppearance: Equatable {
    case `default`
    case hero
}

/**
 *  The row identifier.
 */
enum HomeRowId: Hashable {
    case tvTrending(appearance: HomeRowAppearance)
    case tvLatest
    case tvMostPopular
    case tvSoonExpiring
    case tvLatestForModule(_ module: SRGModule?, type: SRGModuleType)
    case tvLatestForTopic(_ topic: SRGTopic?)
    case tvTopicsAccess
    case tvShowsAccess
    
    case radioLatestEpisodes(channelUid: String)
    case radioMostPopular(channelUid: String)
    case radioLatest(channelUid: String)
    case radioLatestVideos(channelUid: String)
    case radioAllShows(channelUid: String)
    case radioShowsAccess(channelUid: String)
    
    case tvLive
    case radioLive
    case radioLiveSatellite
    
    case tvLiveCenter
    case tvScheduledLivestreams
    
    func publisher() -> AnyPublisher<[HomeRowItem], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        switch self {
            case .tvTrending:
                return dataProvider.tvTrendingMedias(for: vendor, limit: pageSize, editorialLimit: configuration.tvTrendingEditorialLimit?.uintValue,
                                                     episodesOnly: configuration.tvTrendingEpisodesOnly)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvLatest:
                return dataProvider.tvLatestMedias(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvMostPopular:
                return dataProvider.tvMostPopularMedias(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvSoonExpiring:
                return dataProvider.tvSoonExpiringMedias(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .tvLatestForModule(module, type: _):
                guard let urn = module?.urn else { return nil }
                return dataProvider.latestMediasForModule(withUrn: urn, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvTopicsAccess:
                return SRGDataProvider.current!.tvTopics(for: vendor)
                    .map { $0.topics.map { HomeRowItem(rowId: self, content: .topic($0)) } }
                    .eraseToAnyPublisher()
            case let .tvLatestForTopic(topic):
                guard let urn = topic?.urn else { return nil }
                return dataProvider.latestMediasForTopic(withUrn: urn, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioLatestEpisodes(channelUid: channelUid):
                return dataProvider.radioLatestEpisodes(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioMostPopular(channelUid: channelUid):
                return dataProvider.radioMostPopularMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioLatest(channelUid: channelUid):
                return dataProvider.radioLatestMedias(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioLatestVideos(channelUid: channelUid):
                return dataProvider.radioLatestVideos(for: vendor, channelUid: channelUid, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case let .radioAllShows(channelUid):
                return SRGDataProvider.current!.radioShows(for: vendor, channelUid: channelUid, pageSize: SRGDataProviderUnlimitedPageSize)
                    .map { $0.shows.map { HomeRowItem(rowId: self, content: .show($0)) } }
                    .eraseToAnyPublisher()
            case .tvLive:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .radioLive:
                return dataProvider.radioLivestreams(for: vendor, contentProviders: .default)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .radioLiveSatellite:
                return dataProvider.radioLivestreams(for: vendor, contentProviders: .swissSatelliteRadio)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvLiveCenter:
                return dataProvider.liveCenterVideos(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .tvScheduledLivestreams:
                return dataProvider.tvScheduledLivestreams(for: vendor, pageSize: pageSize)
                    .map { $0.medias.map { HomeRowItem(rowId: self, content: .media($0)) } }
                    .eraseToAnyPublisher()
            default:
                return nil
        }
    }
    
    var title: String? {
        switch self {
            case let .tvTrending(appearance: appearance):
                return appearance != .hero ? "Trending videos" : nil
            case .tvLatest:
                return "The latest episodes"
            case .tvMostPopular:
                return "Most popular"
            case .tvSoonExpiring:
                return "Available for a limited time"
            case let .tvLatestForModule(module, type):
                if let module = module {
                    return module.title
                }
                else {
                    return type == .event ? "Event" : "Module"
                }
            case let .tvLatestForTopic(topic):
                return topic?.title ?? "Topic"
            case .tvShowsAccess:
                return "Shows"
            case .radioLatestEpisodes:
                return "The latest audios"
            case .radioMostPopular:
                return "Most listened to"
            case .radioLatest:
                return "The latest audios"
            case .radioLatestVideos:
                return "Latest videos"
            case .radioAllShows:
                return "Shows"
            case .radioShowsAccess:
                return "Shows"
            case .tvLive:
                return "TV channels"
            case .radioLive:
                return "Radio channels"
            case .radioLiveSatellite:
                return "Thematic radios"
            case .tvLiveCenter:
                return "Sport"
            case .tvScheduledLivestreams:
                return "Events"
            default:
                return nil
        }
    }
}

struct HomeRowItem: Hashable {
    // Various kinds of objects which can be displayed on the home.
    enum Content: Hashable {
        case media(_ media: SRGMedia)
        case show(_ show: SRGShow)
        case topic(_ topic: SRGTopic)
        case showsAccess
    }
    
    // Some items might appear in several rows but need to be uniquely defined. We thus add the section to each item
    // to ensure unicity.
    let rowId: HomeRowId
    let content: Content
    
    static func == (lhs: HomeRowItem, rhs: HomeRowItem) -> Bool {
        return lhs.rowId == rhs.rowId && lhs.content == rhs.content
    }
}

class HomeModel: Identifiable, ObservableObject {
    enum Id {
        case video
        case audio(channel: RadioChannel)
        case live
    }
    
    let id: Id
    let rowIds: [HomeRowId]
    
    private var eventRowIds: [HomeRowId] = []
    private var topicRowIds: [HomeRowId] = []
    
    typealias Row = CollectionRow<HomeRowId, HomeRowItem>
    
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
    
    private static func rowIds(for id: Id) -> [HomeRowId] {
        switch id {
            case .video:
                return ApplicationConfiguration.shared.videoHomeRowIds()
            case let .audio(channel):
                return channel.homeRowIds()
            case .live:
                return ApplicationConfiguration.shared.liveHomeRowIds()
        }
    }
    
    private func addRow(with id: HomeRowId, to rows: inout [Row]) {
        if let existingRow = self.rows.first(where: { $0.section == id }) {
            rows.append(existingRow)
        }
        else if case .tvShowsAccess = id {
            rows.append(Row(section: id, items: [HomeRowItem(rowId: id, content: .showsAccess)]))
        }
        else if case .radioShowsAccess = id {
            rows.append(Row(section: id, items: [HomeRowItem(rowId: id, content: .showsAccess)]))
        }
        else {
            rows.append(Row(section: id, items: []))
        }
    }
    
    private func addRows(with ids: [HomeRowId], to rows: inout [Row]) {
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
    
    private func updateRow(with id: HomeRowId, items: [HomeRowItem]) {
        guard let index = rows.firstIndex(where: { $0.section == id }) else { return }
        rows[index] = Row(section: id, items: items)
    }
    
    private func loadRows(with ids: [HomeRowId]? = nil) {
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
                result.modules.map { HomeRowId.tvLatestForModule($0, type: type) }
            }
            .replaceError(with: [])
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
                result.topics.map { HomeRowId.tvLatestForTopic($0) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { rowIds in
                self.topicRowIds = rowIds
                self.synchronizeRows()
                self.loadRows(with: rowIds)
            }
            .store(in: &cancellables)
    }
}
