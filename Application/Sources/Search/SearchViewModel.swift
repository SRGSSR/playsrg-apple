//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import Combine

// MARK: View model

final class SearchViewModel: ObservableObject {
    @Published private(set) var state = State.loading
    
    private let trigger = Trigger()
    
    init() {
        Publishers.PublishAndRepeat(onOutputFrom: reloadSignal()) { [querySubject, trigger] in
            querySubject
                .debounce(for: 0.3, scheduler: DispatchQueue.main)
                .map { query in
                    return Self.searchResults(matchingQuery: query, trigger: trigger)
                }
                .switchToLatest()
                .map { State.loaded(rows: $0.rows, suggestions: $0.suggestions) }
                .catch { error in
                    return Just(State.failed(error: error))
                }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }
    
    var query: String {
        get {
            querySubject.value
        }
        set {
            querySubject.value = newValue
        }
    }
    
    // TODO: Connect with custom settings on iOS
    private static var searchSettings: SRGMediaSearchSettings? {
        guard !ApplicationConfiguration.shared.areSearchSettingsHidden else { return nil }
        
        let settings = SRGMediaSearchSettings()
        settings.aggregationsEnabled = false
        settings.mediaType = constant(iOS: .none, tvOS: .video)
        settings.suggestionsEnabled = true
        return settings
    }
    
    private var querySubject = CurrentValueSubject<String, Never>("")
    
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
    static func mostSearchedShows() -> AnyPublisher<[Row], Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        return SRGDataProvider.current!.mostSearchedShows(for: vendor)
            .map { shows in
                let items = shows.map { Item.show($0) }
                return [Row(section: .mostSearchedShows, items: items)]
            }
            .eraseToAnyPublisher()
    }
    
    static func shows(matchingQuery query: String) -> AnyPublisher<[SRGShow], Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        let pageSize = ApplicationConfiguration.shared.pageSize
        return SRGDataProvider.current!.shows(for: vendor, matchingQuery: query, mediaType: .none, pageSize: pageSize, paginatedBy: nil)
            .map { output in
                return SRGDataProvider.current!.shows(withUrns: output.showUrns)
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    static func medias(matchingQuery query: String, paginatedBy signal: Trigger.Signal) -> AnyPublisher<(medias: [SRGMedia], suggestions: [SRGSearchSuggestion]?), Error> {
        let vendor = ApplicationConfiguration.shared.vendor
        let pageSize = ApplicationConfiguration.shared.pageSize
        return SRGDataProvider.current!.medias(for: vendor, matchingQuery: query, with: Self.searchSettings, pageSize: pageSize, paginatedBy: signal)
            .map { output in
                return SRGDataProvider.current!.medias(withUrns: output.mediaUrns)
                    .map { (medias: $0, suggestions: output.suggestions) }
            }
            .switchToLatest()
            .scan((medias: [], suggestions: nil)) {
                return (medias: $0.medias + $1.medias, suggestions: $1.suggestions )
            }
            .eraseToAnyPublisher()
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
    
    static func searchResults(matchingQuery query: String, trigger: Trigger) -> AnyPublisher<(rows: [Row], suggestions: [SRGSearchSuggestion]?), Error> {
        if !query.isEmpty {
            return Publishers.CombineLatest(
                shows(matchingQuery: query),
                medias(matchingQuery: query, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore))
            )
            .map { (rows: rows(shows: $0, medias: $1.medias), suggestions: $1.suggestions) }
            .eraseToAnyPublisher()
        }
        else {
            return mostSearchedShows()
                .map { (rows: $0, suggestions: nil) }
                .eraseToAnyPublisher()
        }
    }
}
