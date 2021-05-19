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
    typealias Row = CollectionRow<Section, Item>
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(show: SRGShow?, items: [Content.Item])
    }
    
    let section: Section
    
    private static var triggerId = 1
    private var trigger = Trigger()
    
    @Published private(set) var state: State = .loading
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section, filter: SectionFiltering) {
        self.section = section
        
        section.properties.publisher(filter: filter, triggerId: trigger.id(Self.triggerId))?
            .map { items in
                let show = Self.show(from: items)
                let items = Self.items(from: items)
                return State.loaded(show: show, items: items)
            }
            .catch { error -> AnyPublisher<State, Never> in
                return Just(State.failed(error: error))
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }
    
    func loadMore() {
        trigger.signal(Self.triggerId)
    }
    
    private static func show(from items: [Item]) -> SRGShow? {
        if case let .show(show) = items.first {
            return show
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
