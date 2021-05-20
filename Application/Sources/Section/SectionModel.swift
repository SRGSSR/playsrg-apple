//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGDataProviderCombine

class SectionModel: ObservableObject {
    typealias Section = Content.Section
    typealias Item = Content.Item
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(headerItem: Item?, items: [Item])
    }
    
    let section: Section
    
    private var trigger = Trigger()
    @Published private(set) var state: State = .loading
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section, filter: SectionFiltering) {
        self.section = section
        
        section.properties.publisher(filter: filter, triggerId: trigger.id(section))?
            .map { items in
                let headerItem = Self.headerItem(from: items)
                let items = Self.items(from: items)
                return State.loaded(headerItem: headerItem, items: items)
            }
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
    
    private static func headerItem(from items: [Item]) -> Item? {
        if case .show = items.first {
            return items.first
        }
        else {
            return nil
        }
    }
    
    private static func items(from items: [Item]) -> [Item] {
        return items.filter { item in
            if case .media = item {
                return true
            }
            else {
                return false
            }
        }
    }
}
