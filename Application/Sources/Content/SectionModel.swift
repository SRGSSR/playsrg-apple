//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class SectionModel: ObservableObject {
    let section: Section
    
    private var trigger = Trigger()
    @Published private(set) var state: State = .loading
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section, filter: SectionFiltering) {
        self.section = section
        
        section.properties.publisher(filter: filter, triggerId: trigger.id(section))?
            .map { State.loaded(items: $0) }
            .catch { error -> AnyPublisher<State, Never> in
                return Just(State.failed(error: error))
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }
    
    func loadMore() {
        trigger.signal(section)
    }
}

extension SectionModel {
    typealias Section = Content.Section
    typealias Item = Content.Item
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(items: [Item])
    }
}
