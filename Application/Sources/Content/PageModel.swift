//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

class PageModel: Identifiable, ObservableObject {
    enum Id {
        case video
        case audio(channel: RadioChannel)
        case live
    }
    
    let id: Id
    var page: SRGContentPage? {
        didSet {
            self.synchronizeRows()
            self.loadRows()
        }
    }
    
    typealias Section = SRGContentSection
    typealias Item = RowItem
    typealias Row = CollectionRow<SRGContentSection, RowItem>
    
    private var pageSections: [SRGContentSection] {
        return self.page?.sections ?? []
    }
    
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
        self.page = nil
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .sink { notification in
                guard self.pageSections.contains(where: { $0.presentation.type == .favoriteShows }) else { return }
                guard let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .sink { _ in
                guard self.pageSections.contains(where: { $0.presentation.type == .resumePlayback }) else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .sink { notification in
                guard self.pageSections.contains(where: { $0.presentation.type == .watchLater }) else { return }
                guard let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        loadPage()
    }
    
    func refresh() {
        refreshCancellables = []
        
        loadPage()
    }
    
    func cancelRefresh() {
        refreshCancellables = []
    }
        
    private func loadPage() {
        SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, mediaType: .video)
            .map { $0.contentPage }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.page, on: self)
            .store(in: &refreshCancellables)
    }
    
    private func addRow(with section: SRGContentSection, to rows: inout [Row]) {
        if let existingRow = loadedRows.first(where: { $0.section == section }), !existingRow.items.isEmpty {
            rows.append(existingRow)
        }
        else {
            rows.append(Row(section: section, items: placeholderItems(for: section)))
        }
    }
    
    private func addRows(with ids: [SRGContentSection], to rows: inout [Row]) {
        for id in ids {
            addRow(with: id, to: &rows)
        }
    }
    
    private func synchronizeRows() {
        var updatedRows = [Row]()
        for section in pageSections {
            addRow(with: section, to: &updatedRows)
        }
        loadedRows = updatedRows
    }
    
    private func updateRow(with section: SRGContentSection, items: [RowItem]) {
        guard let index = loadedRows.firstIndex(where: { $0.section == section }) else { return }
        loadedRows[index] = Row(section: section, items: items)
    }
    
    private func loadRows(with ids: [SRGContentSection]? = nil) {
        let reloadedContentSections = ids ?? pageSections
        for section in reloadedContentSections {
            sectionPublisher(section)?
                .replaceError(with: [])
                .receive(on: DispatchQueue.main)
                .sink { items in
                    self.updateRow(with: section, items: items)
                }
                .store(in: &refreshCancellables)
        }
    }
    
    private func placeholderItems(for section: SRGContentSection) -> [RowItem] {
        guard section.isSupported else {return [] }
        
        let numberOfPlaceholders = 10
        
        switch section.presentation.type {
        case .topicSelector:
            return (0..<numberOfPlaceholders).map { RowItem(section: section, content: .topicPlaceholder(index: $0)) }
        case .favoriteShows, .resumePlayback, .watchLater:
            return []
            // TODO: Show section
//            case .radioAllShows:
//                return (0..<Self.numberOfPlaceholders).map { RowItem(rowId: self, content: .showPlaceholder(index: $0)) }
        default:
            return (0..<numberOfPlaceholders).map { RowItem(section: section, content: .mediaPlaceholder(index: $0)) }
        }
    }
}

extension PageModel {
    enum RowAppearance: Equatable {
        case `default`
        case hero
    }
}

extension PageModel {
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
        let section: SRGContentSection
        let content: Content
    }
}

extension PageModel {
    func sectionPublisher(_ section: SRGContentSection) -> AnyPublisher<[RowItem], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        switch section.type {
        case .medias:
            return dataProvider.medias(for: section.vendor, contentSectionUid: section.uid, pageSize: pageSize)
                .map { $0.medias.map { RowItem(section: section, content: .media($0)) } }
                .eraseToAnyPublisher()
            
        case .showAndMedias:
            return dataProvider.showAndMedias(for: section.vendor, contentSectionUid: section.uid, pageSize: pageSize)
                // TODO: add the show object first
                .map { $0.showAndMedias.medias.map { RowItem(section: section, content: .media($0)) } }
                .eraseToAnyPublisher()
        case .shows:
            return dataProvider.shows(for: section.vendor, contentSectionUid: section.uid, pageSize: pageSize)
                .map { $0.shows.map { RowItem(section: section, content: .show($0)) } }
                .eraseToAnyPublisher()
        case .predefined:
            switch section.presentation.type {
            case .favoriteShows:
                return showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { self.compatibleShows($0, inSection: section).map { RowItem(section: section, content: .show($0)) } }
                    .eraseToAnyPublisher()
//            case .tvFavoriteLatestEpisodes:
//                return showsPublisher(withUrns: Array(FavoritesShowURNs()))
//                    .map { compatibleShows($0).map { $0.urn } }
//                    .flatMap { urns in
//                        return latestMediasForShowsPublisher(withUrns: urns)
//                    }
//                    .map { $0.map { RowItem(rowId: self, content: .media($0)) } }
//                    .eraseToAnyPublisher()
            case .livestreams:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.medias.map { RowItem(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .topicSelector:
                return dataProvider.tvTopics(for: vendor)
                    .map { $0.topics.map { RowItem(section: section, content: .topic($0)) } }
                    .eraseToAnyPublisher()
            case .resumePlayback:
                return historyPublisher()
                    .map { self.compatibleMedias($0).prefix(Int(pageSize)).map { RowItem(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .watchLater:
                return laterPublisher()
                    .map { self.compatibleMedias($0).prefix(Int(pageSize)).map { RowItem(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
    private func canContain(show: SRGShow) -> Bool {
        switch self.id {
        case .video:
            return show.transmission == .TV
        case .audio:
            // TODO: filter by channelUid
            return show.transmission == .radio // && show.primaryChannelUid == channelUid
        default:
            return false
        }
    }
    
    private func compatibleShows(_ shows: [SRGShow], inSection: SRGContentSection) -> [SRGShow] {
        return shows.filter { canContain(show: $0) }.sorted(by: { $0.title < $1.title })
    }
    
    private func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
        switch self.id {
        case .video:
            return medias.filter { $0.mediaType == .video }
        case .audio:
            return medias.filter { $0.mediaType == .audio }
        default:
            return medias
        }
    }
    
    private func showsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGShow], Error> {
        let dataProvider = SRGDataProvider.current!
        let pagePublisher = CurrentValueSubject<SRGDataProvider.Shows.Page?, Never>(nil)
        
        // TODO: Fix for iOS 13
        if #available(iOS 14.0, *) {
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
        else {
            return dataProvider.shows(withUrns: urns, pageSize: 50 /* Use largest page size */)
                .map { $0.shows }
                .eraseToAnyPublisher()
        }
    }
        
    private func latestMediasForShowsPublisher(withUrns urns: [String]) -> AnyPublisher<[SRGMedia], Error> {
        // TODO: The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
//        /* Load latest 15 medias for each 3 shows, get last 30 episodes */
//        return urns.publisher
//            .collect(3)
//            .flatMap { urns in
//                return SRGDataProvider.current!.latestMediasForShows(withUrns: urns, filter: .episodesOnly, pageSize: 15)
//            }
//            .reduce([SRGMedia]()) { collectedMedias, result in
//                return collectedMedias + result.medias
//            }
//            .map { medias in
//                return Array(medias.sorted(by: { $0.date > $1.date }).prefix(30))
//            }
//            .eraseToAnyPublisher()
        return Empty()
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
}

extension SRGContentSection {
    var isLive: Bool {
        if case .livestreams = presentation.type {
            return true
        }
        else {
            return false
        }
    }
    
    var isFavoriteShows: Bool {
        if case .favoriteShows = presentation.type {
            return true
        }
        else {
            return false
        }
    }
    
    var isSupported: Bool {
        switch presentation.type {
        case .none, .events, .personalizedProgram:
            return false
        case .swimlane, .hero, .grid, .mediaHighlight, .showHighlight:
            return true
        case .favoriteShows, .livestreams, .topicSelector, .resumePlayback, .watchLater:
            return true
        @unknown default:
            return false
        }
    }
}

/**
 *  Collection row.
 */
struct CollectionRow<Section: Hashable, Item: Hashable>: Hashable {
    /// Section.
    let section: Section
    /// Items contained within the section.
    let items: [Item]
}
