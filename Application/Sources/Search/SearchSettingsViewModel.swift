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
    @Published var settings: SRGMediaSearchSettings?
    
    @Published private(set) var state: State = .loading
    
    private static func enrichedSettings(from settings: SRGMediaSearchSettings?) -> SRGMediaSearchSettings {
        let settingsCopy = settings?.copy() as? SRGMediaSearchSettings ?? SRGMediaSearchSettings()
        settingsCopy.aggregationsEnabled = true
        return settingsCopy
    }
    
    init() {
        Publishers.PublishAndRepeat(onOutputFrom: reloadSignal()) { [$query, $settings] in
            Publishers.CombineLatest($query, $settings)
                .map { query, settings -> AnyPublisher<State, Never> in
                    let vendor = ApplicationConfiguration.shared.vendor
                    let enrichedSettings = Self.enrichedSettings(from: settings)
                    return SRGDataProvider.current!.medias(for: vendor, matchingQuery: query, with: enrichedSettings)
                        .map { State.loaded(aggregations: $0.aggregations) }
                        .catch { error in
                            return Just(State.failed(error: error))
                        }
                        .eraseToAnyPublisher()
                }
                .switchToLatest()
                .prepend(State.loading)
        }
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
    
    private func reloadSignal() -> AnyPublisher<Void, Never> {
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
    
    enum Period {
        case anytime
        case today
        case yesterday
        case thisWeek
        case lastWeek
    }
    
    enum Duration {
        case any
        case lessThanFiveMinutes
        case moreThanThirtyMinutes
    }
}
