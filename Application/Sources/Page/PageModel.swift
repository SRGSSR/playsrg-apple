//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

class PageModel: Identifiable, ObservableObject {
    let id: Id
    
    var title: String? {
        switch id {
        case .video, .audio, .live:
            return nil
        case let .topic(topic: topic):
            #if os(tvOS)
            return topic.title
            #else
            return nil
            #endif
        }
    }
    
    @Published private(set) var state: State = .loading
    
    private let trigger = Trigger()
    
    private var internalState: State = .loading {
        didSet {
            state = Self.state(from: internalState)
        }
    }
    
    private var rows: [Row] {
        if case let .loaded(rows: rows) = internalState {
            return rows
        }
        else {
            return []
        }
    }
    
    private var sections: [Section] {
        return rows.map { $0.section }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(id: Id) {
        self.id = id
    }
    
    func refresh() {
        cancellables = []
        
        Just((id: self.id, rows: rows, trigger: trigger))
            .throttle(for: 30, scheduler: RunLoop.main, latest: true)
            .flatMap { context in
                return SRGDataProvider.current!.rowsPublisher(id: context.id, existingRows: context.rows, trigger: context.trigger)
                    .map { State.loaded(rows: $0) }
                    .catch { error -> AnyPublisher<State, Never> in
                        if context.rows.count != 0 {
                            return Just(State.loaded(rows: context.rows))
                                .eraseToAnyPublisher()
                        }
                        else {
                            return Just(State.failed(error: error))
                                .eraseToAnyPublisher()
                        }
                    }
            }
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.internalState, on: self)
            .store(in: &cancellables)
    }
    
    func loadMore() {
        if let lastSection = sections.last, lastSection.properties.isGridLayout {
            trigger.signal(lastSection)
        }
    }
    
    func cancelRefresh() {
        cancellables = []
    }
    
    private static func state(from internalState: State) -> State {
        if case let .loaded(rows: rows) = internalState {
            return .loaded(rows: rows.filter { !$0.items.isEmpty })
        }
        else {
            return internalState
        }
    }
}

fileprivate extension SRGDataProvider {
    /// Publishes rows associated with a page id, starting from the provided rows. Updates are published down the pipeline
    /// as they are retrieved.
    func rowsPublisher(id: PageModel.Id, existingRows: [PageModel.Row], trigger: Trigger) -> AnyPublisher<[PageModel.Row], Error> {
        return sectionsPublisher(id: id)
            // For each section create a publisher which updates the associated row and publishes the entire updated
            // row list as a result. A value is sent down the pipeline with each update.
            .flatMap { sections -> AnyPublisher<[PageModel.Row], Never> in
                var rows = Self.reusableRows(from: existingRows, for: sections)
                return Publishers.MergeMany(sections.map { section in
                    return self.rowPublisher(id: id, section: section, trigger: trigger)
                        .map { row in
                            guard let index = rows.firstIndex(where: { $0.section == section }) else { return rows }
                            rows[index] = row
                            return rows
                        }
                        .eraseToAnyPublisher()
                })
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// Publishes sections associated with a page id
    func sectionsPublisher(id: PageModel.Id) -> AnyPublisher<[PageModel.Section], Error> {
        switch id {
        case .video:
            return contentPage(for: ApplicationConfiguration.shared.vendor, mediaType: .video)
                .map { $0.sections.map { PageModel.Section.content($0) } }
                .eraseToAnyPublisher()
        case let .topic(topic: topic):
            return contentPage(for: ApplicationConfiguration.shared.vendor, topicWithUrn: topic.urn)
                .map { $0.sections.map { PageModel.Section.content($0) } }
                .eraseToAnyPublisher()
        case let .audio(channel: channel):
            return Just(channel.configuredSections().map { PageModel.Section.configured($0) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .live:
            return Just(ApplicationConfiguration.shared.liveConfiguredSections().map { PageModel.Section.configured($0) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    /// Publishes the row for content for a given section and page id
    func rowPublisher(id: PageModel.Id, section: PageModel.Section, trigger: Trigger) -> AnyPublisher<PageModel.Row, Never> {
        if let publisher = section.properties.publisher(for: id, triggerId: trigger.id(section)) {
            return publisher
                .replaceError(with: section.properties.placeholderItems)
                .map { PageModel.Row(section: section, items: Self.removeDuplicateItems($0)) }
                .eraseToAnyPublisher()
        }
        else {
            return Just(PageModel.Row(section: section, items: []))
                .eraseToAnyPublisher()
        }
    }
    
    /**
     *  Unique items: remove duplicated items. Items must not appear more than one time in the same row.
     *
     *  Idea borrowed from https://www.hackingwithswift.com/example-code/language/how-to-remove-duplicate-items-from-an-array
     */
    private static func removeDuplicateItems<T: Hashable>(_ items: [T]) -> [T] {
        var itemDictionnary = [T: Bool]()
        
        return items.filter {
            let isNew = itemDictionnary.updateValue(true, forKey: $0) == nil
            if !isNew {
                PlayLogWarning(category: "collection", message: "A duplicate item has been removed: \($0)")
            }
            return isNew
        }
    }
    
    private static func reusableRows(from existingRows: [PageModel.Row], for sections: [PageModel.Section]) -> [PageModel.Row] {
        return sections.map { section in
            if let existingRow = existingRows.first(where: { $0.section == section }) {
                return existingRow
            }
            else {
                return PageModel.Row(section: section, items: section.properties.placeholderItems)
            }
        }
    }
}
