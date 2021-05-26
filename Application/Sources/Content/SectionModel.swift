//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FXReachability
import SRGDataProviderCombine

// MARK: View model

class SectionModel: ObservableObject {
    let section: Content.Section
    
    @Published private(set) var state: State = .loading
    
    private var trigger = Trigger()
    private var cancellables = Set<AnyCancellable>()
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Content.Section, filter: SectionFiltering?) {
        self.section = section
        
        Publishers.PublishAndRepeat(onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)) { [trigger] in
            return section.properties.publisher(pageSize: ApplicationConfiguration.shared.detailPageSize,
                                                paginatedBy: trigger.triggerable(activatedBy: TriggerId.loadMore),
                                                filter: filter)
                .scan([]) { $0 + $1 }
                .map { State.loaded(row: Row(section: SectionModel.Section(section), items: removeDuplicates(in: $0))) }
                .catch { error in
                    return Just(State.failed(error: error))
                }
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
        trigger.activate(for: TriggerId.loadMore)
    }
    
    func reload() {
        trigger.activate(for: TriggerId.reload)
    }
}

// MARK: Types

extension SectionModel {
    struct Section: Hashable {
        let wrappedValue: Content.Section
        
        init(_ wrappedValue: Content.Section) {
            self.wrappedValue = wrappedValue
        }
        
        var properties: SectionProperties {
            return wrappedValue.properties
        }
        
        var viewModelProperties: SectionViewModelProperties {
            switch wrappedValue {
            case let .content(section):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }
    
    typealias Item = Content.Item
    typealias Row = CollectionRow<Section, Item>
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(row: Row)
        
        var isEmpty: Bool {
            if case let .loaded(row) = self {
                return row.isEmpty
            }
            else {
                return true
            }
        }
    }
    
    enum SectionLayout: Hashable {
        case liveMediaGrid
        case mediaGrid
        case showGrid
        case topicGrid
    }
    
    enum TriggerId {
        case loadMore
        case reload
    }
}

// MARK: Properties

protocol SectionViewModelProperties {
    var layout: SectionModel.SectionLayout { get }
}

private extension SectionModel {
    struct ContentSectionProperties: SectionViewModelProperties {
        let contentSection: SRGContentSection
        
        var layout: SectionModel.SectionLayout {
            switch contentSection.presentation.type {
            case .hero, .mediaHighlight, .resumePlayback, .watchLater, .personalizedProgram:
                return .mediaGrid
            case .showHighlight, .favoriteShows:
                return .showGrid
            case .topicSelector:
                return .topicGrid
            case .livestreams:
                return .liveMediaGrid
            case .swimlane, .grid:
                return (contentSection.type == .shows) ? .showGrid : .mediaGrid
            case .none, .showAccess:
                return .mediaGrid
            }
        }
    }
    
    struct ConfiguredSectionProperties: SectionViewModelProperties {
        let configuredSection: ConfiguredSection
        
        var layout: SectionModel.SectionLayout {
            switch configuredSection.type {
            case .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos, .tvLiveCenter, .tvScheduledLivestreams:
                return .mediaGrid
            case .tvLive, .radioLive, .radioLiveSatellite:
                return .liveMediaGrid
            case .radioFavoriteShows, .radioAllShows:
                return .showGrid
            case .radioShowAccess:
                return .mediaGrid
            }
        }
    }
}
