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
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section, filter: SectionFiltering?) {
        self.section = section
        
        let pageSize = ApplicationConfiguration.shared.pageSize
        
        section.properties.publisher(pageSize: pageSize,
                                     paginatedBy: trigger.triggerable(activatedBy: TriggerId.loadMore),
                                     reloadedBy: trigger.triggerable(activatedBy: TriggerId.reload),
                                     filter: filter)
            .map { State.loaded(row: Row(section: section, items: removeDuplicates(in: $0))) }
            .catch { error in
                return Just(State.failed(error: error))
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
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
