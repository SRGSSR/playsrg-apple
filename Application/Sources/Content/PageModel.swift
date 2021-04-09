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
            state = Self.state(from: internalState)
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
            .sink { [weak self] notification in
                guard let self = self, self.sections.contains(where: { $0.properties.presentationType == .favoriteShows }),
                      let domains = notification.userInfo?[SRGPreferencesDomainsKey] as? Set<String>, domains.contains(PlayPreferencesDomain) else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGHistoryEntriesDidChange, object: SRGUserData.current?.history)
            .sink { [weak self] _ in
                guard let self = self, self.sections.contains(where: { $0.properties.presentationType == .resumePlayback }) else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.SRGPlaylistEntriesDidChange, object: SRGUserData.current?.playlists)
            .sink { [weak self] notification in
                guard let self = self, self.sections.contains(where: { $0.properties.presentationType == .watchLater }),
                      let playlistUid = notification.userInfo?[SRGPlaylistUidKey] as? String, playlistUid == SRGPlaylistUid.watchLater.rawValue else { return }
                self.refresh()
            }
            .store(in: &mainCancellables)
    }
    
    func refresh() {
        refreshCancellables = []
        
        Self.rowsPublisher(id: id, existingRows: rows)
            .map { State.loaded(rows: $0) }
            .catch { error in
                return Just(State.failed(error: error))
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.internalState, on: self)
            .store(in: &refreshCancellables)
    }
    
    func cancelRefresh() {
        refreshCancellables = []
    }
    
    private static func reusableRows(from existingRows: [Row], for sections: [Section]) -> [Row] {
        return sections.map { section in
            if let existingRow = existingRows.first(where: { $0.section == section }) {
                return existingRow
            }
            else {
                return Row(section: section, items: section.properties.placeholderItems)
            }
        }
    }
    
    private static func state(from internalState: State) -> State {
        if case let .loaded(rows: rows) = internalState {
            return .loaded(rows: rows.filter { !$0.items.isEmpty })
        }
        else {
            return internalState
        }
    }
}

extension PageModel {
    /// Publishes rows associated with a page id, starting from the provided rows and updating them as they are retrieved
    private static func rowsPublisher(id: Id, existingRows: [Row]) -> AnyPublisher<[Row], Error> {
        return sectionsPublisher(id: id)
            // For each section create a publisher which updates the associated row and publishes the entire updated
            // row list as a result. A value is sent down the pipeline with each update.
            .flatMap { sections -> AnyPublisher<[Row], Never> in
                var rows = reusableRows(from: existingRows, for: sections)
                return Publishers.MergeMany(sections.map { section in
                    Self.rowPublisher(id: id, section: section)
                        .map { row in
                            guard let index = rows.firstIndex(where: { $0.section == section }) else { return rows }
                            rows[index] = row
                            return rows
                        }
                        .eraseToAnyPublisher()
                })
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Publishes sections associated with a page id
    private static func sectionsPublisher(id: Id) -> AnyPublisher<[Section], Error> {
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
    
    /// Publishes the row for content for a given section and page id
    private static func rowPublisher(id: Id, section: Section) -> AnyPublisher<Row, Never> {
        if let publisher = section.properties.publisher(for: id) {
            return publisher
                .replaceError(with: section.properties.placeholderItems)
                .map { Row(section: section, items: $0) }
                .eraseToAnyPublisher()
        }
        else {
            return Just(Row(section: section, items: []))
                .eraseToAnyPublisher()
        }
    }
}
