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
    
    @Published private(set) var state: State = .loading(aggregations: nil)
    
    private static func enrichedSettings(from settings: MediaSearchSettings?) -> MediaSearchSettings {
        var enrichedSettings = settings ?? MediaSearchSettings()
        enrichedSettings.aggregationsEnabled = true
        return enrichedSettings
    }
    
    private static func description(forSelectedUrns selectedUrns: Set<String>?, in buckets: [SRGItemBucket]) -> String? {
        guard let selectedUrns else { return nil }
        let selectedBuckets = buckets
            .filter { selectedUrns.contains($0.urn) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        guard !selectedBuckets.isEmpty else { return nil }
        return selectedBuckets.map(\.title).joined(separator: ", ")
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
                        .prepend(State.loading(aggregations: self?.aggregations))
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
        switch state {
        case let .loading(aggregations: aggregations):
            return aggregations
        case let .loaded(aggregations: aggregations):
            return aggregations
        case .failed:
            return nil
        }
    }
    
    var hasTopicFilter: Bool {
        return !topicBuckets.isEmpty
    }
    
    var topicBuckets: [SRGItemBucket] {
        return aggregations?.topicBuckets ?? []
    }
    
    var selectedTopics: String? {
        return Self.description(forSelectedUrns: settings?.topicUrns, in: topicBuckets)
    }
    
    var hasShowFilter: Bool {
        return !showBuckets.isEmpty
    }
    
    var showBuckets: [SRGItemBucket] {
        return aggregations?.showBuckets ?? []
    }
    
    var selectedShows: String? {
        return Self.description(forSelectedUrns: settings?.showUrns, in: showBuckets)
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
        case loading(aggregations: SRGMediaAggregations?)
        case failed(error: Error)
        case loaded(aggregations: SRGMediaAggregations?)
    }
}
