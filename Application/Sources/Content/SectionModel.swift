//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

// MARK: View model

class SectionModel: ObservableObject {
    let section: Section
    
    private var trigger = Trigger()
    @Published private(set) var state: State = .loading
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section, filter: SectionFiltering) {
        self.section = section
        
        if let publisher = section.properties.publisher(filter: filter, triggerId: trigger.id(section)) {
            publisher
                .map { State.loaded(items: $0) }
                .catch { error -> AnyPublisher<State, Never> in
                    return Just(State.failed(error: error))
                        .eraseToAnyPublisher()
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
    }
}
