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
    
    init(section: Section, filter: SectionFiltering) {
        self.section = section
        
        if let publisher = section.properties.publisher(filter: filter, triggerId: trigger.id(section)) {
            NotificationCenter.default.publisher(for: NSNotification.Name.FXReachabilityStatusDidChange, object: nil)
                .filter { notification in
                    return ReachabilityBecameReachable(notification) && self.state.isEmpty
                }
                .map { _ in }
                .prepend(())
                .flatMap {
                    return publisher
                        .scan([]) { $0 + $1 }
                        .map { State.loaded(items: $0) }
                        .catch { error -> AnyPublisher<State, Never> in
                            if !self.state.isEmpty {
                                return Just(self.state)
                                    .eraseToAnyPublisher()
                            }
                            else {
                                return Just(State.failed(error: error))
                                    .eraseToAnyPublisher()
                            }
                        }
                }
                .receive(on: DispatchQueue.main)
                .assign(to: &$state)
        }
        else {
            self.state = .loaded(items: [])
        }
    }
    
    func loadMore() {
        trigger.signal(section)
    }
}

// MARK: Types

extension SectionModel {
    typealias Section = Content.Section
    typealias Item = Content.Item
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(items: [Item])
        
        var isEmpty: Bool {
            if case let .loaded(items) = self {
                return items.isEmpty
            }
            else {
                return true
            }
        }
    }
}
