//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine

// MARK: View model

final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var settings = SearchViewModel.optimalSettings()

    @Published private(set) var state = State.loading

    private let trigger = Trigger()

    var hasDefaultSettings: Bool {
        Self.areDefaultSettings(settings)
    }

    init() {
        Publishers.CombineLatest($query.removeDuplicates(), $settings)
            .debounceAfterFirst(for: 0.3, scheduler: DispatchQueue.main)
            .map { [weak self, trigger] query, settings in
                Publishers.PublishAndRepeat(onOutputFrom: self?.reloadSignal()) {
                    Self.rows(matchingQuery: query, with: settings, trigger: trigger)
                        .map { Self.state(from: $0.rows, suggestions: $0.suggestions) }
                        .catch { error in
                            Just(State.failed(error: error))
                        }
                        .prepend(State.loading)
                }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }

    var isSearching: Bool {
        Self.isSearching(with: query, settings: settings)
    }

    func reload(deep: Bool = false) {
        if deep || !state.hasContent {
            trigger.activate(for: TriggerId.reload)
        }
    }

    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }

    func resetSettings() {
        settings = Self.optimalSettings()
    }

    private func reloadSignal() -> AnyPublisher<Void, Never> {
        Publishers.Merge3(
            trigger.signal(activatedBy: TriggerId.reload),
            ApplicationSignal.wokenUp()
                .filter { [weak self] in
                    guard let self else { return false }
                    return !state.hasContent
                },
            ApplicationSignal.foregroundAfterTimeInBackground()
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
        .eraseToAnyPublisher()
    }

    static func areDefaultSettings(_ settings: MediaSearchSettings) -> Bool {
        optimalSettings(from: settings) == optimalSettings()
    }

    private static func isSearching(with query: String, settings: MediaSearchSettings) -> Bool {
        !query.isEmpty || !areDefaultSettings(settings)
    }

    private static func optimalSettings(from settings: MediaSearchSettings = MediaSearchSettings()) -> MediaSearchSettings {
        var optimalSettings = settings
        #if os(tvOS)
            optimalSettings.mediaType = .video
            optimalSettings.suggestionsEnabled = true
        #endif
        optimalSettings.aggregationsEnabled = false
        return optimalSettings
    }
}

// MARK: Types

extension SearchViewModel {
    enum State {
        case loading
        case failed(error: Error)
        case loaded(rows: [Row], suggestions: [SRGSearchSuggestion]?)

        var hasContent: Bool {
            if case let .loaded(rows: rows, suggestions: _) = self {
                !rows.isEmpty
            } else {
                false
            }
        }
    }

    enum Section: Hashable {
        case medias
        case shows
        case topics
        case loading
    }

    enum Item: Hashable {
        case media(_ media: SRGMedia)
        case show(_ show: SRGShow)
        case topic(_ topic: SRGTopic)
        case loading
    }

    typealias Row = CollectionRow<Section, Item>

    enum TriggerId {
        case loadMore
        case reload
    }
}

// MARK: Publishers

private extension SearchViewModel {
    static func searchSuggestion() -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if !ApplicationConfiguration.shared.areShowsUnavailable {
            topics()
                .map { (rows: [$0], suggestions: nil) }
                .eraseToAnyPublisher()
        } else {
            Just([])
                .map { (rows: $0, suggestions: nil) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }

    static func searchResults(matchingQuery query: String, with settings: MediaSearchSettings, trigger: Trigger) -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if !ApplicationConfiguration.shared.areShowsUnavailable {
            if !query.isEmpty {
                Publishers.CombineLatest(
                    shows(matchingQuery: query, with: settings),
                    medias(matchingQuery: query, with: settings, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore))
                )
                .map { (rows: [$0, $1.row], suggestions: $1.suggestions) }
                .eraseToAnyPublisher()
            } else {
                medias(matchingQuery: query, with: settings, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore))
                    .map { (rows: [$0.row], suggestions: $0.suggestions) }
                    .eraseToAnyPublisher()
            }
        } else {
            medias(matchingQuery: query, with: nil /* Case of SWI; settings not supported */, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore))
                .map { (rows: [$0.row], suggestions: $0.suggestions) }
                .eraseToAnyPublisher()
        }
    }

    static func shows(matchingQuery query: String, with settings: MediaSearchSettings) -> AnyPublisher<Row, Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        let pageSize = ApplicationConfiguration.shared.detailPageSize
        return SRGDataProvider.current!.shows(for: vendor, matchingQuery: query, mediaType: settings.mediaType, pageSize: pageSize, paginatedBy: nil)
            .map { output in
                SRGDataProvider.current!.shows(withUrns: output.showUrns, pageSize: pageSize)
                    .map { $0.map { Item.show($0) } }
            }
            .switchToLatest()
            .prepend([Item.loading])
            .map { Row(section: .shows, items: $0) }
            .eraseToAnyPublisher()
    }

    static func medias(matchingQuery query: String, with settings: MediaSearchSettings?, paginatedBy signal: Trigger.Signal) -> AnyPublisher<(row: Row, suggestions: [SRGSearchSuggestion]?), Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        let pageSize = ApplicationConfiguration.shared.detailPageSize
        return SRGDataProvider.current!.medias(for: vendor, matchingQuery: query, with: settings?.requestSettings, pageSize: pageSize, paginatedBy: signal)
            .map { output in
                SRGDataProvider.current!.medias(withUrns: output.mediaUrns, pageSize: pageSize)
                    .map { (items: $0.map { Item.media($0) }, suggestions: output.suggestions) }
            }
            .switchToLatest()
            .scan((items: [], suggestions: nil)) {
                (items: removeDuplicates(in: $0.items + $1.items), suggestions: $1.suggestions)
            }
            .prepend((items: [Item.loading], suggestions: nil))
            .map { (row: Row(section: .medias, items: $0.items), suggestions: $0.suggestions) }
            .eraseToAnyPublisher()
    }

    static func topics() -> AnyPublisher<Row, Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        return SRGDataProvider.current!.tvTopics(for: vendor)
            .map { removeDuplicates(in: $0.map { Item.topic($0) }) }
            .prepend([Item.loading])
            .map { Row(section: .topics, items: $0) }
            .eraseToAnyPublisher()
    }

    static func rows(matchingQuery query: String, with settings: MediaSearchSettings, trigger: Trigger) -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if isSearching(with: query, settings: settings) {
            searchResults(matchingQuery: query, with: settings, trigger: trigger)
        } else {
            searchSuggestion()
        }
    }

    static func isLoading(row: Row) -> Bool {
        row.items.contains { $0 == .loading }
    }

    static func state(from rows: [Row], suggestions: [SRGSearchSuggestion]?) -> State {
        let loadingRows = rows.filter { isLoading(row: $0) }
        if loadingRows.isEmpty {
            let filledRows = rows.filter { !$0.items.isEmpty }
            return .loaded(rows: filledRows, suggestions: suggestions)
        } else {
            let filledRows = rows.filter { !isLoading(row: $0) && !$0.items.isEmpty }
            if !filledRows.isEmpty {
                let rows = filledRows.appending(Row(section: .loading, items: [.loading]))
                return .loaded(rows: rows, suggestions: suggestions)
            } else {
                return .loading
            }
        }
    }
}
