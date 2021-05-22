//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

// MARK: Publishers

extension SRGDataProvider {
    static func pageSize() -> UInt {
        return ApplicationConfiguration.shared.pageSize
    }
    
    /// Publishes rows associated with a page id, starting from the provided rows. Updates are published down the pipeline
    /// as they are retrieved.
    func rowsPublisher(id: PageModel.Id, existingRows: [PageModel.Row], trigger: Trigger) -> AnyPublisher<[PageModel.Row], Error> {
        return sectionsPublisher(id: id)
            // For each section create a publisher which updates the associated row and publishes the entire updated
            // row list as a result. A value is sent down the pipeline with each update.
            .map { sections -> AnyPublisher<[PageModel.Row], Never> in
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
            .switchToLatest()
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
        if let publisher = section.properties.publisher(pageSize: Self.pageSize(), paginatedBy: trigger.triggerable(activatedBy: section), filter: id) {
            return publisher
                .scan([]) { $0 + $1 }
                .replaceError(with: section.properties.placeholderItems)
                .map { PageModel.Row(section: section, items: Self.rowItems(removeDuplicates(in: $0), in: section)) }
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
    private static func rowItems(_ items: [Content.Item], in section: PageModel.Section) -> [PageModel.Item] {
        var rowItems = items.map { PageModel.Item(.item($0), in: section) }
        if rowItems.count >= Self.pageSize() && section.layoutProperties.canOpenDetailPage && section.layoutProperties.hasSwimlaneLayout {
            rowItems.append(PageModel.Item(.more, in: section))
        }
        return rowItems
    }
    
    private static func reusableRows(from existingRows: [PageModel.Row], for sections: [PageModel.Section]) -> [PageModel.Row] {
        return sections.map { section in
            if let existingRow = existingRows.first(where: { $0.section == section }) {
                return existingRow
            }
            else {
                return PageModel.Row(section: section, items: rowItems(section.properties.placeholderItems, in: section))
            }
        }
    }
}
