//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FXReachability
import SRGDataProviderCombine

// MARK: View model

class SectionModel: ObservableObject {
    let section: Section
    
    @Published private(set) var state: State = .loading
    
    private var trigger = Trigger()
    private var cancellables = Set<AnyCancellable>()
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section, filter: SectionFiltering?) {
        self.section = section
        
        Publishers.PublishAndRepeat(onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)) { [trigger] in
            return section.properties.publisher(pageSize: ApplicationConfiguration.shared.detailPageSize,
                                                paginatedBy: trigger.triggerable(activatedBy: TriggerId.loadMore),
                                                filter: filter)
                .scan([]) { $0 + $1 }
                .map { State.loaded(row: Row(section: section, items: removeDuplicates(in: $0))) }
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
    typealias Section = Content.Section
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
    
    enum TriggerId {
        case loadMore
        case reload
    }
}
