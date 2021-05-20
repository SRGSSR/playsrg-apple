//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

// MARK: Publishers

extension SRGDataProvider {
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
                .map { $0.sections.map { PageModel.Section(.content($0)) } }
                .eraseToAnyPublisher()
        case let .topic(topic: topic):
            return contentPage(for: ApplicationConfiguration.shared.vendor, topicWithUrn: topic.urn)
                .map { $0.sections.map { PageModel.Section(.content($0)) } }
                .eraseToAnyPublisher()
        case let .audio(channel: channel):
            return Just(channel.configuredSections().map { PageModel.Section(.configured($0)) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .live:
            return Just(ApplicationConfiguration.shared.liveConfiguredSections().map { PageModel.Section(.configured($0)) })
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    /// Publishes the row for content for a given section and page id
    func rowPublisher(id: PageModel.Id, section: PageModel.Section, trigger: Trigger) -> AnyPublisher<PageModel.Row, Never> {
        if let publisher = section.properties.publisher(filter: id, triggerId: trigger.id(section)) {
            return publisher
                .scan([]) { $0 + $1 }
                .replaceError(with: section.properties.placeholderItems)
                .map { PageModel.Row(section: section, items: Self.items(Self.removeDuplicateItems($0), in: section)) }
                .eraseToAnyPublisher()
        }
        else {
            return Just(PageModel.Row(section: section, items: []))
                .eraseToAnyPublisher()
        }
    }
}

// MARK: Helpers

private extension SRGDataProvider {
    private static func items(_ items: [Content.Item], in section: PageModel.Section) -> [PageModel.Item] {
        return items.map { PageModel.Item($0, in: section) }
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
                return PageModel.Row(section: section, items: items(section.properties.placeholderItems, in: section))
            }
        }
    }
}
