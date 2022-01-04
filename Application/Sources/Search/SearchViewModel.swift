//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import Combine

// MARK: View model

final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var settings: SRGMediaSearchSettings = SearchViewModel.optimalSettings()
    
    @Published private(set) var state = State.loading
    
    private let trigger = Trigger()
    
    init() {
        Publishers.PublishAndRepeat(onOutputFrom: reloadSignal()) { [$query, $settings, trigger] in
            Publishers.CombineLatest($query.removeDuplicates(), $settings)
                .debounce(for: 0.3, scheduler: DispatchQueue.main)
                .map { query, settings -> AnyPublisher<State, Never> in
                    return Self.rows(matchingQuery: query, with: settings, trigger: trigger)
                        .map { State.loaded(rows: $0.rows, suggestions: $0.suggestions) }
                        .catch { error in
                            return Just(State.failed(error: error))
                        }
                        .prepend(State.loading)
                        .eraseToAnyPublisher()
                }
                .switchToLatest()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }
    
    var isSearching: Bool {
        return Self.isSearching(with: query, settings: settings)
    }
    
    func reload(deep: Bool = false) {
        if deep || !state.hasContent {
            trigger.activate(for: TriggerId.reload)
        }
    }
    
    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }
    
    private func reloadSignal() -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            trigger.signal(activatedBy: TriggerId.reload),
            ApplicationSignal.wokenUp()
                .filter { [weak self] in
                    guard let self = self else { return false }
                    return !self.state.hasContent
                }
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
        .eraseToAnyPublisher()
    }
    
    static func areDefaultSettings(_ settings: SRGMediaSearchSettings) -> Bool {
        return optimalSettings(from: settings) == optimalSettings()
    }
    
    private static func isSearching(with query: String, settings: SRGMediaSearchSettings) -> Bool {
        return !query.isEmpty || !Self.areDefaultSettings(settings)
    }
    
    private static func optimalSettings(from settings: SRGMediaSearchSettings = SRGMediaSearchSettings()) -> SRGMediaSearchSettings {
        let settingsCopy = settings.copy() as! SRGMediaSearchSettings
#if os(tvOS)
        settingsCopy.mediaType = .video
        settingsCopy.suggestionsEnabled = true
#endif
        settingsCopy.aggregationsEnabled = false
        return settingsCopy
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
                return !rows.isEmpty
            }
            else {
                return false
            }
        }
    }
    
    enum Section: Hashable {
        case medias
        case shows
        case mostSearchedShows
    }
    
    enum Item: Hashable {
        case media(_ media: SRGMedia)
        case show(_ show: SRGShow)
    }
    
    typealias Row = CollectionRow<Section, Item>
    
    enum TriggerId {
        case loadMore
        case reload
    }
}

// MARK: Publishers

private extension SearchViewModel {
    static func mostSearchedShows() -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if !ApplicationConfiguration.shared.areShowsUnavailable {
            let vendor = ApplicationConfiguration.shared.vendor
            return SRGDataProvider.current!.mostSearchedShows(for: vendor)
                .map { shows in
                    let items = removeDuplicates(in: shows.map { Item.show($0) })
                    return [Row(section: .mostSearchedShows, items: items)]
                }
                .map { (rows: $0, suggestions: nil) }
                .eraseToAnyPublisher()
        }
        else {
            return Just([])
                .map { (rows: $0, suggestions: nil) }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    static func searchResults(matchingQuery query: String, with settings: SRGMediaSearchSettings, trigger: Trigger) -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if !ApplicationConfiguration.shared.areShowsUnavailable {
            return Publishers.CombineLatest(
                shows(matchingQuery: query),
                medias(matchingQuery: query, with: settings, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore))
            )
            .map { (rows: rows(shows: $0, medias: $1.medias), suggestions: $1.suggestions) }
            .eraseToAnyPublisher()
        }
        else {
            return medias(matchingQuery: query, with: nil /* Not supported */, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore))
                .map { (rows: rows(shows: [], medias: $0.medias), suggestions: $0.suggestions) }
                .eraseToAnyPublisher()
        }
    }
    
    static func shows(matchingQuery query: String) -> AnyPublisher<[SRGShow], Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        let pageSize = ApplicationConfiguration.shared.detailPageSize
        return SRGDataProvider.current!.shows(for: vendor, matchingQuery: query, mediaType: constant(iOS: .none, tvOS: .video), pageSize: pageSize, paginatedBy: nil)
            .map { output in
                return SRGDataProvider.current!.shows(withUrns: output.showUrns, pageSize: pageSize)
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    static func medias(matchingQuery query: String, with settings: SRGMediaSearchSettings?, paginatedBy signal: Trigger.Signal) -> AnyPublisher<(medias: [SRGMedia], suggestions: [SRGSearchSuggestion]?), Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        let pageSize = ApplicationConfiguration.shared.detailPageSize
        return SRGDataProvider.current!.medias(for: vendor, matchingQuery: query, with: settings, pageSize: pageSize, paginatedBy: signal)
            .map { output in
                return SRGDataProvider.current!.medias(withUrns: output.mediaUrns, pageSize: pageSize)
                    .map { (medias: $0, suggestions: output.suggestions) }
            }
            .switchToLatest()
            .scan((medias: [], suggestions: nil)) {
                return (medias: removeDuplicates(in: $0.medias + $1.medias), suggestions: $1.suggestions )
            }
            .eraseToAnyPublisher()
    }
    
    static func rows(matchingQuery query: String, with settings: SRGMediaSearchSettings, trigger: Trigger) -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if Self.isSearching(with: query, settings: settings) {
            return Self.searchResults(matchingQuery: query, with: settings, trigger: trigger)
        }
        else {
            return Self.mostSearchedShows()
        }
    }
    
    static func rows(shows: [SRGShow], medias: [SRGMedia]) -> [Row] {
        var rows = [Row]()
        if !shows.isEmpty {
            let items = shows.map { Item.show($0) }
            rows.append(Row(section: .shows, items: items))
        }
        if !medias.isEmpty {
            let items = medias.map { Item.media($0) }
            rows.append(Row(section: .medias, items: items))
        }
        return rows
    }
}
