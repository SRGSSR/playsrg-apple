//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine

// MARK: View model

final class SearchSettingsViewModel: ObservableObject {
    @Published var query: String?
    @Published var settings: MediaSearchSettings?
    
    @Published private(set) var state: State = .loading
    
    private static func enrichedSettings(from settings: MediaSearchSettings?) -> MediaSearchSettings {
        var enrichedSettings = settings ?? MediaSearchSettings()
        enrichedSettings.aggregationsEnabled = true
        return enrichedSettings
    }
    
    init() {
        // Drop initial values; relevant values are first assigned when the view appears
        Publishers.CombineLatest($query.dropFirst(), $settings.dropFirst())
            .map { [weak self] query, settings in
                return Publishers.PublishAndRepeat(onOutputFrom: self?.reloadSignal()) { () -> AnyPublisher<SearchSettingsViewModel.State, Never> in
                    let vendor = ApplicationConfiguration.shared.vendor
                    let enrichedSettings = Self.enrichedSettings(from: settings)
                    return SRGDataProvider.current!.medias(for: vendor, matchingQuery: query, with: enrichedSettings.requestSettings)
                        .map { State.loaded(aggregations: $0.aggregations) }
                        .catch { error in
                            return Just(State.failed(error: error))
                        }
                        .prepend(State.loading)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }
    
    var isLoadingFilters: Bool {
        switch state {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    private var aggregations: SRGMediaAggregations? {
        if case let .loaded(aggregations: aggregations) = state, let aggregations = aggregations {
            return aggregations
        }
        else {
            return nil
        }
    }
    
    var hasTopicFilter: Bool {
        guard let aggregations = aggregations else { return false }
        return !aggregations.topicBuckets.isEmpty
    }
    
    var topicBuckets: [Bucket] {
        guard let aggregations = aggregations else { return [] }
        return aggregations.topicBuckets.map { Bucket(from: $0) }
    }
    
    var selectedTopics: String? {
        guard let aggregations = aggregations, let settings = settings else { return nil }
        let selectedBuckets = aggregations.topicBuckets.filter { settings.topicUrns.contains($0.urn) }
        guard !selectedBuckets.isEmpty else { return nil }
        return selectedBuckets.map(\.title).joined(separator: ", ")
    }
    
    var hasShowFilter: Bool {
        guard let aggregations = aggregations else { return false }
        return !aggregations.showBuckets.isEmpty
    }
    
    var showsBuckets: [Bucket] {
        guard let aggregations = aggregations else { return [] }
        return aggregations.showBuckets.map { Bucket(from: $0) }
    }
    
    var selectedShows: String? {
        guard let aggregations = aggregations, let settings = settings else { return nil }
        let selectedBuckets = aggregations.showBuckets.filter { settings.showUrns.contains($0.urn) }
        guard !selectedBuckets.isEmpty else { return nil }
        return selectedBuckets.map(\.title).joined(separator: ", ")
    }
    
    var hasSubtitledFilter: Bool {
        return !ApplicationConfiguration.shared.isSearchSettingSubtitledHidden
    }
    
    private func reloadSignal() -> AnyPublisher<Void, Never> {
        return ApplicationSignal.wokenUp()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .eraseToAnyPublisher()
    }
}

// MARK: Types

extension SearchSettingsViewModel {
    enum State {
        case loading
        case failed(error: Error)
        case loaded(aggregations: SRGMediaAggregations?)
    }
}
