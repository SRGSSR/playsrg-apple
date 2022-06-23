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
            .map { query, settings in
                return Publishers.PublishAndRepeat(onOutputFrom: Self.reloadSignal()) { () -> AnyPublisher<SearchSettingsViewModel.State, Never> in
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
    
    var hasTopicFilter: Bool {
        if case let .loaded(aggregations: aggregations) = state, let aggregations = aggregations {
            return !aggregations.topicBuckets.isEmpty
        }
        else {
            return false
        }
    }
    
    var topicBuckets: [SearchSettingsBucket] {
        if case let .loaded(aggregations: aggregations) = state, let aggregations = aggregations {
            return aggregations.topicBuckets.map { SearchSettingsBucket(bucket: .topic(topic: $0)) }
        }
        else {
            return []
        }
    }
    
    var hasShowFilter: Bool {
        if case let .loaded(aggregations: aggregations) = state, let aggregations = aggregations {
            return !aggregations.showBuckets.isEmpty
        }
        else {
            return false
        }
    }
    
    var showsBuckets: [SearchSettingsBucket] {
        if case let .loaded(aggregations: aggregations) = state, let aggregations = aggregations {
            return aggregations.showBuckets.map { SearchSettingsBucket(bucket: .show(show: $0)) }
        }
        else {
            return []
        }
    }
    
    var hasSubtitledFilter: Bool {
        return !ApplicationConfiguration.shared.isSearchSettingSubtitledHidden
    }
    
    private static func reloadSignal() -> AnyPublisher<Void, Never> {
        return ApplicationSignal.wokenUp()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .eraseToAnyPublisher()
    }
    
    struct SearchSettingsBucket: Swift.Identifiable, Equatable {
        enum Bucket {
            case topic(topic: SRGTopicBucket)
            case show(show: SRGShowBucket)
        }
        
        let bucket: Bucket
        
        var id: String {
            switch bucket {
            case let .topic(topic):
                return topic.urn
            case let .show(show):
                return show.urn
            }
        }
        
        var title: String {
            switch bucket {
            case let .topic(topic):
                return "\(topic.title) (\(NumberFormatter.localizedString(from: topic.count as NSNumber, number: .decimal)))"
            case let .show(show):
                return "\(show.title) (\(NumberFormatter.localizedString(from: show.count as NSNumber, number: .decimal)))"
            }
        }
        
        static func == (lhs: SearchSettingsBucket, rhs: SearchSettingsBucket) -> Bool {
            return lhs.id == rhs.id
        }
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
