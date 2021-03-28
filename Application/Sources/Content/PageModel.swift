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
        case topic(topic: SRGTopic)
    }
    
    let id: Id
    
    private var page: SRGContentPage? {
        didSet {
            self.synchronizeRows()
            self.loadRows()
        }
    }
    
    typealias Section = RowSection
    typealias Item = RowItem
    typealias Row = CollectionRow<Section, Item>
    
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
        switch self.id {
        case .video:
            SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, mediaType: .video)
                .map { $0.contentPage }
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
                .assign(to: \.page, on: self)
                .store(in: &refreshCancellables)
        case let .topic(topic: topic):
            SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, topicWithUrn: topic.urn)
                .map { $0.contentPage }
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
                .assign(to: \.page, on: self)
                .store(in: &refreshCancellables)
        case .audio, .live: break
        }
    }
    
    private func addRow(with contentSection: SRGContentSection, to rows: inout [Row]) {
        if let existingRow = loadedRows.first(where: { $0.section.contentSection == contentSection }), !existingRow.items.isEmpty {
            rows.append(existingRow)
        }
        else {
            rows.append(Row(section: Section(contentSection: contentSection), items: placeholderItems(for: contentSection)))
        }
    }
    
    private func synchronizeRows() {
        var updatedRows = [Row]()
        for contentSection in pageSections {
            addRow(with: contentSection, to: &updatedRows)
        }
        loadedRows = updatedRows
    }
    
    private func updateRow(with contentSection: SRGContentSection, items: [Item]) {
        guard let index = loadedRows.firstIndex(where: { $0.section.contentSection == contentSection }) else { return }
        loadedRows[index] = Row(section: Section(contentSection: contentSection), items: items)
    }
    
    private func loadRows(with ids: [SRGContentSection]? = nil) {
        let reloadedContentSections = ids ?? pageSections
        for contentSection in reloadedContentSections {
            contentSectionPublisher(contentSection)?
                .replaceError(with: [])
                .receive(on: DispatchQueue.main)
                .sink { items in
                    self.updateRow(with: contentSection, items: items)
                }
                .store(in: &refreshCancellables)
        }
    }
    
    private func placeholderItems(for contentSection: SRGContentSection) -> [Item] {
        let defaultNumberOfPlaceholders = 10
        let section = Section(contentSection: contentSection)
        
        switch contentSection.presentation.type {
        case .mediaHighlight:
            return [ Item(section: section, content: .mediaPlaceholder(index: 0)) ]
        case .showHighlight:
            return [ Item(section: section, content: .showPlaceholder(index: 0)) ]
        case .topicSelector:
            return (0..<defaultNumberOfPlaceholders).map { Item(section: section, content: .topicPlaceholder(index: $0)) }
        case .swimlane, .hero, .grid, .livestreams:
            return (0..<defaultNumberOfPlaceholders).map { Item(section: section, content: .mediaPlaceholder(index: $0)) }
        case .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram:
            // Could be empty
            return []
        case .none, .showAccess:
            return []
        }
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
            
            #if os(iOS)
            case showAccess
            #endif
        }
        
        // Some items might appear in several rows but need to be uniquely defined. We thus add the section to each item
        // to ensure unicity.
        let section: RowSection
        let content: Content
    }
    
    struct RowSection: Hashable {
        var title: String? {
            if contentSection.type == .predefined {
                switch contentSection.presentation.type {
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
                    return NSLocalizedString("Shows", comment: "Title label used to present the TV or radio shows AZ and TV shows by date access buttons")
                case .none, .topicSelector, .swimlane, .hero, .grid, .mediaHighlight, .showHighlight:
                    return nil
                }
            }
            else {
                return contentSection.presentation.title
            }
        }
        
        var summary: String? {
            return contentSection.presentation.summary
        }
        
        var isLive: Bool {
            if case .livestreams = contentSection.presentation.type {
                return true
            }
            else {
                return false
            }
        }
        
        // Various kinds of layouts which can be displayed on the home.
        enum Layout: Hashable {
            case featured
            case highlighted
            case topicSelector
            #if os(iOS)
            case showAccess
            #endif
            case shows
            case medias
        }
        
        var layout: Layout {
            switch contentSection.presentation.type {
            case .hero:
                return .featured
            case .mediaHighlight, .showHighlight:
                return .highlighted
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
                if contentSection.type == .shows {
                    return .shows
                }
                else {
                    return .medias
                }
            case .livestreams, .resumePlayback, .watchLater, .personalizedProgram:
                return .medias
            case .none:
                // Not supported
                return .medias
            }
        }
        
        fileprivate let contentSection: SRGContentSection
    }
}

extension PageModel {
    private func contentSectionPublisher(_ contentSection: SRGContentSection) -> AnyPublisher<[Item], Error>? {
        let dataProvider = SRGDataProvider.current!
        let configuration = ApplicationConfiguration.shared
        
        let vendor = configuration.vendor
        let pageSize = configuration.pageSize
        
        let section = Section(contentSection: contentSection)
        
        switch contentSection.type {
        case .medias:
            return dataProvider.medias(for: contentSection.vendor, contentSectionUid: contentSection.uid, pageSize: pageSize)
                .map { self.filterItems($0.medias, section: contentSection).map { Item(section: section, content: .media($0)) } }
                .eraseToAnyPublisher()
        case .showAndMedias:
            return dataProvider.showAndMedias(for: contentSection.vendor, contentSectionUid: contentSection.uid, pageSize: pageSize)
                .map { var items = [Item]()
                    if let show = $0.showAndMedias.show { items.append(Item(section: section, content: .show(show))) }
                    items.append(contentsOf: $0.showAndMedias.medias.map { Item(section: section, content: .media($0)) })
                    return items
                }
                .eraseToAnyPublisher()
        case .shows:
            return dataProvider.shows(for: contentSection.vendor, contentSectionUid: contentSection.uid, pageSize: pageSize)
                .map { self.filterItems($0.shows, section: contentSection).map { Item(section: section, content: .show($0)) } }
                .eraseToAnyPublisher()
        case .predefined:
            switch contentSection.presentation.type {
            case .favoriteShows:
                return showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { self.compatibleShows($0, inSection: contentSection).map { Item(section: section, content: .show($0)) } }
                    .eraseToAnyPublisher()
            case .personalizedProgram:
                return showsPublisher(withUrns: Array(FavoritesShowURNs()))
                    .map { self.compatibleShows($0, inSection: contentSection).map { $0.urn } }
                    .flatMap { urns in
                        return self.latestMediasForShowsPublisher(withUrns: urns)
                    }
                    .map { $0.map { Item(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .livestreams:
                return dataProvider.tvLivestreams(for: vendor)
                    .map { $0.medias.map { Item(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .topicSelector:
                return dataProvider.tvTopics(for: vendor)
                    .map { $0.topics.map { Item(section: section, content: .topic($0)) } }
                    .eraseToAnyPublisher()
            case .resumePlayback:
                return historyPublisher()
                    .map { self.compatibleMedias($0).prefix(Int(pageSize)).map { Item(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .watchLater:
                return laterPublisher()
                    .map { self.compatibleMedias($0).prefix(Int(pageSize)).map { Item(section: section, content: .media($0)) } }
                    .eraseToAnyPublisher()
            case .showAccess:
                #if os(iOS)
                return CurrentValueSubject([ Item(section: section, content: .showAccess) ])
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
}

extension PageModel {
    private func canContain(show: SRGShow) -> Bool {
        switch self.id {
        case .video:
            return show.transmission == .TV
        case let .audio(channel: channel):
            return show.transmission == .radio && show.primaryChannelUid == channel.uid
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
        case let .audio(channel: channel):
            return medias.filter { $0.mediaType == .audio && $0.channel?.uid == channel.uid }
        default:
            return medias
        }
    }
    
    private func filterItems<T>(_ items: [T], section: SRGContentSection) -> [T] {
        guard section.presentation.type == .mediaHighlight || section.presentation.type == .showHighlight else { return items }
        
        if section.presentation.isRandomized, let item = items.randomElement() {
            return [ item ]
        }
        else if !section.presentation.isRandomized, let item = items.first {
            return [ item ]
        }
        else {
            return []
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
