//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

class PageModel: Identifiable, ObservableObject {
    let id: Id
    
    var title: String? {
        switch id {
        case .video, .audio, .live:
            return nil
        case let .topic(topic: topic):
            #if os(tvOS)
            return topic.title
            #else
            return nil
            #endif
        }
    }
    
    @Published private(set) var state: State = .loading
    
    private var internalState: State = .loading {
        didSet {
            state = Self.nonEmptyState(internalState)
        }
    }
    
    private var rows: [Row] {
        if case let .loaded(rows: rows) = internalState {
            return rows
        }
        else {
            return []
        }
    }
    
    private var sections: [Section] {
        return rows.map { $0.section }
    }
    
    private var mainCancellables = Set<AnyCancellable>()
    private var refreshCancellables = Set<AnyCancellable>()
    
    init(id: Id) {
        self.id = id
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPreferencesDidChange, object: SRGUserData.current?.preferences)
            .sink { notification in
                guard self.sections.contains(where: { $0.properties.presentationType == .favoriteShows }),
                      let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .sink { _ in
                guard self.sections.contains(where: { $0.properties.presentationType == .resumePlayback }) else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .sink { notification in
                guard self.sections.contains(where: { $0.properties.presentationType == .watchLater }),
                      let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        loadSections()
    }
    
    func refresh() {
        refreshCancellables = []
        loadSections()
    }
    
    func cancelRefresh() {
        refreshCancellables = []
    }
        
    private func loadSections() {
        sectionsPublisher()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveRequest: { _ in
                if self.rows.isEmpty {
                    self.internalState = .loading
                }
            })
            .sink { completion in
                if case let .failure(error) = completion, self.rows.isEmpty {
                    self.internalState = .failed(error: error)
                }
            } receiveValue: { result in
                let rows = Self.refreshRows(id: self.id, sections: result, from: self.rows, in: &self.refreshCancellables) { section, items in
                    self.internalState = .loaded(rows: Self.updatedRows(section: section, items: items, from: self.rows))
                }
                self.internalState = .loaded(rows: rows)
            }
            .store(in: &refreshCancellables)
    }
    
    private func sectionsPublisher() -> AnyPublisher<[Section], Error> {
        switch id {
        case .video:
            return SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, mediaType: .video)
                .map { $0.contentPage.sections.map { Section.content($0) } }
                .eraseToAnyPublisher()
        case let .topic(topic: topic):
            return SRGDataProvider.current!.contentPage(for: ApplicationConfiguration.shared.vendor, topicWithUrn: topic.urn)
                .map { $0.contentPage.sections.map { Section.content($0) } }
                .eraseToAnyPublisher()
        case let .audio(channel: channel):
            return Just(channel.configuredSections().map { Section.configured($0) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .live:
            return Just(ApplicationConfiguration.shared.liveConfiguredSections().map { Section.configured($0) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    private static func nonEmptyState(_ state: State) -> State {
        if case let .loaded(rows: rows) = state {
            return .loaded(rows: rows.filter { !$0.items.isEmpty })
        }
        else {
            return state
        }
    }
    
    private static func appendRow(section: Section, from existingRows: [Row], to rows: inout [Row]) {
        if let existingRow = existingRows.first(where: { $0.section == section }) {
            rows.append(existingRow)
        }
        else {
            rows.append(Row(section: section, items: section.properties.placeholderItems(for: section)))
        }
    }
    
    // TODO: Could maybe have a [Row] publisher to update the state as rows are loaded. Like a network request, rewrite
    //       refresh:
    //         - Just() publisher with initial array of rows
    //         - flatmap for each section, sending updates down the stream
    private static func refreshRows(id: Id, sections: [Section], from existingRows: [Row], in cancellables: inout Set<AnyCancellable>, update: @escaping (Section, [Item]) -> Void) -> [Row] {
        var rows = [Row]()
        for section in sections {
            appendRow(section: section, from: existingRows, to: &rows)
            section.properties.publisher(for: id, section: section)?
                .replaceError(with: [])
                .receive(on: DispatchQueue.main)
                .sink { items in
                    update(section, items)
                }
                .store(in: &cancellables)
        }
        return rows
    }
    
    private static func updatedRows(section: Section, items: [Item], from existingRows: [Row]) -> [Row] {
        guard let index = existingRows.firstIndex(where: { $0.section == section }) else { return existingRows }
        var rows = existingRows
        rows[index] = Row(section: section, items: items)
        return rows
    }
}
