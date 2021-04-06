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
        
        func canContain(show: SRGShow) -> Bool {
            switch self {
            case .video:
                return show.transmission == .TV
            case let .audio(channel: channel):
                return show.transmission == .radio && show.primaryChannelUid == channel.uid
            default:
                return false
            }
        }
        
        func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
            return shows.filter { canContain(show: $0) }.sorted(by: { $0.title < $1.title })
        }
        
        func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
            switch self {
            case .video:
                return medias.filter { $0.mediaType == .video }
            case let .audio(channel: channel):
                return medias.filter { $0.mediaType == .audio && $0.channel?.uid == channel.uid }
            default:
                return medias
            }
        }
    }
    
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
    
    typealias Row = CollectionRow<Section, Item>
    
    private var sections: [Section] = [] {
        didSet {
            refreshRows()
        }
    }
    
    // Store all rows so that row updates always find a matching row. Only return non-empty ones publicly, though
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
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.sections, on: self)
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
            return Just(channel.playSections().map { Section.play($0) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .live:
            return Just(ApplicationConfiguration.shared.liveHomePlaySections().map { Section.play($0) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    private func addRow(with section: Section, to rows: inout [Row]) {
        if let existingRow = loadedRows.first(where: { $0.section == section }), !existingRow.items.isEmpty {
            rows.append(existingRow)
        }
        else {
            rows.append(Row(section: section, items: section.properties.placeholderItems(for: section)))
        }
    }
    
    private func refreshRows() {
        synchronizeRows()
        loadRows()
    }
    
    private func synchronizeRows() {
        var updatedRows = [Row]()
        for section in sections {
            addRow(with: section, to: &updatedRows)
        }
        loadedRows = updatedRows
    }
    
    private func updateRow(section: Section, items: [Item]) {
        guard let index = loadedRows.firstIndex(where: { $0.section == section }) else { return }
        loadedRows[index] = Row(section: section, items: items)
    }
    
    private func loadRows() {
        for section in sections {
            section.properties.publisher(for: id, section: section)?
                .replaceError(with: [])
                .receive(on: DispatchQueue.main)
                .sink { items in
                    self.updateRow(section: section, items: items)
                }
                .store(in: &refreshCancellables)
        }
    }
}
