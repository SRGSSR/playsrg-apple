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
        
        if let publisher = section.properties.publisher(paginatedBy: trigger.triggerable(activatedBy: TriggerId.loadMore), filter: filter) {
            publisher
                .scan([]) { $0 + $1 }
                .map { State.loaded(row: Row(section: section, items: removeDuplicates(in: $0))) }
                .catch { error in
                    return Just(State.failed(error: error))
                }
                .publishAgain(on: reloadSignal())
                .receive(on: DispatchQueue.main)
                .assign(to: &$state)
        }
        else {
            self.state = .loaded(row: Row(section: section, items: []))
        }
    }
    
    func loadMore() {
        trigger.activate(for: TriggerId.loadMore)
    }
    
    func reload() {
        trigger.activate(for: TriggerId.reload)
    }
    
    func reloadSignal() -> AnyPublisher<Void, Never> {
        return Publishers.Merge(
            // TODO: Model should probably conform to some protocol for models, with a method to tell if empty.
            //       In this case the model should just be provided to the notification pipeline, in a stateless
            //       way, avoiding capture issues
            NotificationCenter.default.publisher(for: NSNotification.Name.FXReachabilityStatusDidChange, object: nil)
                .filter { [weak self] notification in
                    guard let self = self else { return false }
                    return ReachabilityBecameReachable(notification) && self.state.isEmpty
                }
                .map { _ in },
            trigger.signal(activatedBy: TriggerId.reload)
        )
        .eraseToAnyPublisher()
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
