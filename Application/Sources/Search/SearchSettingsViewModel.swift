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
    
    var hasTopicFilter: Bool {
        if case let .loaded(aggregations: aggregations) = state, let aggregations = aggregations {
            return !aggregations.topicBuckets.isEmpty
        }
        else {
            return false
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
