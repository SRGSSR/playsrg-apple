//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

// MARK: View model

class PageModel: Identifiable, ObservableObject {
    let id: Id
    
    var title: String? {
        switch id {
        case .video, .audio, .live:
            return nil
        case let .topic(topic: topic):
            return topic.title
        }
    }
    
    @Published private(set) var state: State = .loading
    
    private let trigger = Trigger()
    private var cancellables = Set<AnyCancellable>()
    
    init(id: Id) {
        self.id = id
        
        Publishers.PublishAndRepeat(onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)) { [weak self] in
            return SRGDataProvider.current!.sectionsPublisher(id: id)
                .map { sections in
                    return Publishers.AccumulateLatestMany(sections.map { section in
                        return Publishers.PublishAndRepeat(onOutputFrom: Self.rowReloadSignal(for: section, trigger: self?.trigger)) {
                            return SRGDataProvider.current!.rowPublisher(id: id,
                                                                         section: section,
                                                                         pageSize: Self.pageSize(for: section, in: sections),
                                                                         paginatedBy: self?.trigger.signal(activatedBy: TriggerId.loadMore(section: section))
                            )
                            .replaceError(with: Self.placeholderRow(for: section, state: self?.state))
                            .prepend(Self.placeholderRow(for: section, state: self?.state))
                            .eraseToAnyPublisher()
                        }
                    })
                    .eraseToAnyPublisher()
                }
                .switchToLatest()
                .map { State.loaded(rows: $0.filter { !$0.isEmpty } ) }
                .catch { error in
                    return Just(State.failed(error: error))
                }
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
        
        Signal.wokenUp()
            .sink { [weak self] in
                self?.reload()
            }
            .store(in: &cancellables)
    }
    
    func loadMore() {
        if let lastSection = state.sections.last, Self.hasLoadMore(for: lastSection, in: state.sections) {
            trigger.activate(for: TriggerId.loadMore(section: lastSection))
        }
    }
    
    func reload(deep: Bool = false) {
        if deep || state.sections.isEmpty {
            trigger.activate(for: TriggerId.reload)
        }
        else {
            for section in state.sections where !Self.hasLoadMore(for: section, in: state.sections) {
                trigger.activate(for: TriggerId.reloadSection(section))
            }
        }
    }
    
    private static func rowReloadSignal(for section: PageModel.Section, trigger: Trigger?) -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            section.viewModelProperties.reloadSignal() ?? PassthroughSubject<Void, Never>().eraseToAnyPublisher(),
            trigger?.signal(activatedBy: PageModel.TriggerId.reloadSection(section)) ?? PassthroughSubject<Void, Never>().eraseToAnyPublisher()
        )
        .eraseToAnyPublisher()
    }
    
    private static func hasLoadMore(for section: Section, in sections: [Section]) -> Bool {
        if section == sections.last && section.viewModelProperties.hasGridLayout {
            return true
        }
        else {
            return false
        }
    }
    
    private static func pageSize(for section: Section, in sections: [Section]) -> UInt {
        let configuration = ApplicationConfiguration.shared
        return hasLoadMore(for: section, in: sections) ? configuration.detailPageSize : configuration.pageSize
    }
    
    private static func placeholderRow(for section: Section, state: State?) -> Row {
        if let row = state?.rows.first(where: { $0.section == section }) {
            return row
        }
        else {
            return PageModel.Row(section: section, items: Self.placeholderRowItems(for: section))
        }
    }
    
    private static func placeholderRowItems(for section: Section) -> [Item] {
        return section.properties.placeholderItems.map { Item(.item($0), in: section) }
    }
}

// MARK: Types

extension PageModel {
    enum Id: SectionFiltering {
        case video
        case audio(channel: RadioChannel)
        case live
        case topic(topic: SRGTopic)
        
        var supportsCastButton: Bool {
            switch self {
            case .video, .audio, .live:
                return true
            default:
                return false
            }
        }
        
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
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(rows: [Row])
        
        var rows: [Row] {
            if case let .loaded(rows: rows) = self {
                return rows
            }
            else {
                return []
            }
        }
        
        var sections: [Section] {
            return rows.map(\.section)
        }
        
        var isEmpty: Bool {
            return rows.isEmpty
        }
    }
    
    enum SectionLayout: Hashable {
        case hero
        case highlight
        case highlightSwimlane
        case liveMediaGrid
        case liveMediaSwimlane
        case mediaGrid
        case mediaSwimlane
        case showGrid
        case showSwimlane
        case topicSelector
        
        @available(tvOS, unavailable)
        case showAccess
    }
    
    struct Section: Hashable {
        let wrappedValue: Content.Section
        
        init(_ wrappedValue: Content.Section) {
            self.wrappedValue = wrappedValue
        }
        
        var properties: SectionProperties {
            return wrappedValue.properties
        }
        
        var viewModelProperties: PageViewModelProperties {
            switch wrappedValue {
            case let .content(section):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }
    
    struct Item: Hashable {
        enum WrappedValue: Hashable {
            case item(Content.Item)
            case more
        }
        
        let wrappedValue: WrappedValue
        let section: Section
        
        init(_ wrappedValue: WrappedValue, in section: Section) {
            self.wrappedValue = wrappedValue
            self.section = section
        }
    }
    
    typealias Row = CollectionRow<Section, Item>
    
    enum TriggerId: Hashable {
        case reload
        case reloadSection(Section)
        case loadMore(section: Section)
    }
}

// MARK: Publishers

private extension SRGDataProvider {
    func sectionsPublisher(id: PageModel.Id) -> AnyPublisher<[PageModel.Section], Error> {
        switch id {
        case .video:
            return contentPage(for: ApplicationConfiguration.shared.vendor, mediaType: .video)
                .map { $0.sections.map { PageModel.Section(.content($0)) } }
                .eraseToAnyPublisher()
        case let .topic(topic: topic):
            return contentPage(for: ApplicationConfiguration.shared.vendor, topicWithUrn: topic.urn)
                .map { $0.sections.map { PageModel.Section(.content($0)) } }
                .eraseToAnyPublisher()
        case let .audio(channel: channel):
            return Just(channel.configuredSections().map { PageModel.Section(.configured($0)) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .live:
            return Just(ApplicationConfiguration.shared.liveConfiguredSections().map { PageModel.Section(.configured($0)) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    func rowPublisher(id: PageModel.Id, section: PageModel.Section, pageSize: UInt, paginatedBy paginator: Trigger.Signal?) -> AnyPublisher<PageModel.Row, Error> {
        return section.properties.publisher(pageSize: pageSize, paginatedBy: paginator, filter: id)
            .scan([]) { $0 + $1 }
            .map { Self.rowItems(removeDuplicates(in: $0), in: section) }
            .map { PageModel.Row(section: section, items: $0) }
            .eraseToAnyPublisher()
    }
    
    static func rowItems(_ items: [Content.Item], in section: PageModel.Section) -> [PageModel.Item] {
        var rowItems = items.map { PageModel.Item(.item($0), in: section) }
        if rowItems.count > 0 && section.viewModelProperties.canOpenDetailPage && section.viewModelProperties.hasSwimlaneLayout {
            rowItems.append(PageModel.Item(.more, in: section))
        }
        return rowItems
    }
}

// MARK: Properties

protocol PageViewModelProperties {
    var layout: PageModel.SectionLayout { get }
    var canOpenDetailPage: Bool { get }
    
    /// Signal which can be used to reload the section entirely
    func reloadSignal() -> AnyPublisher<Void, Never>?
}

extension PageViewModelProperties {
    var accessibilityHint: String? {
        if canOpenDetailPage {
            return PlaySRGAccessibilityLocalizedString("Shows all contents.", "Homepage header action hint")
        }
        else {
            return nil
        }
    }
    
    var hasSwimlaneLayout: Bool {
        switch layout {
        case .mediaSwimlane, .showSwimlane:
            return true
        default:
            return false
        }
    }
    
    var hasGridLayout: Bool {
        switch layout {
        case .mediaGrid, .showGrid, .liveMediaGrid:
            return true
        default:
            return false
        }
    }
}

private extension PageModel {
    struct ContentSectionProperties: PageViewModelProperties {
        let contentSection: SRGContentSection
        
        private var presentation: SRGContentPresentation {
            return contentSection.presentation
        }
        
        var layout: PageModel.SectionLayout {
            switch presentation.type {
            case .hero:
                return .hero
            case .mediaHighlight, .showHighlight:
                return .highlight
            case .mediaHighlightSwimlane:
                return .highlightSwimlane
            case .topicSelector:
                return .topicSelector
            case .showAccess:
                #if os(iOS)
                return .showAccess
                #else
                // Not supported
                return .mediaSwimlane
                #endif
            case .favoriteShows:
                return .showSwimlane
            case .swimlane:
                return (contentSection.type == .shows) ? .showSwimlane : .mediaSwimlane
            case .grid:
                return (contentSection.type == .shows) ? .showGrid : .mediaGrid
            case .livestreams:
                return .liveMediaSwimlane
            case .none, .resumePlayback, .watchLater, .personalizedProgram:
                return .mediaSwimlane
            }
        }
        
        var canOpenDetailPage: Bool {
            switch presentation.type {
            case .favoriteShows, .resumePlayback, .watchLater, .personalizedProgram:
                return true
            default:
                return presentation.hasDetailPage
            }
        }
        
        func reloadSignal() -> AnyPublisher<Void, Never>? {
            switch presentation.type {
            case .favoriteShows, .personalizedProgram:
                return Signal.favoritesUpdate()
            case .resumePlayback:
                return Signal.historyUpdate()
            case .watchLater:
                return Signal.laterUpdate()
            default:
                return nil
            }
        }
    }
    
    struct ConfiguredSectionProperties: PageViewModelProperties {
        let configuredSection: ConfiguredSection
        
        var layout: PageModel.SectionLayout {
            switch configuredSection.type {
            case .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
                return (configuredSection.contentPresentationType == .hero) ? .hero : .mediaSwimlane
            case .tvLive, .radioLive, .radioLiveSatellite:
                #if os(iOS)
                return .liveMediaGrid
                #else
                return .liveMediaSwimlane
                #endif
            case .tvLiveCenter, .tvScheduledLivestreams:
                return .mediaSwimlane
            case .radioFavoriteShows:
                return .showSwimlane
            case .radioAllShows:
                return .showGrid
            case .radioShowAccess:
                #if os(iOS)
                return .showAccess
                #else
                // Not supported
                return .mediaSwimlane
                #endif
            }
        }
        
        var canOpenDetailPage: Bool {
            return layout == .mediaSwimlane || layout == .showSwimlane
        }
        
        func reloadSignal() -> AnyPublisher<Void, Never>? {
            switch configuredSection.type {
            case .radioFavoriteShows:
                return Signal.favoritesUpdate()
            default:
                return nil
            }
        }
    }
}
