//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

protocol SectionFiltering {
    func compatibleShows(_ shows: [SRGShow]) -> [SRGShow]
    func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia]
}

protocol SectionProperties {
    var title: String? { get }
    var summary: String? { get }
    var label: String? { get }
    var placeholderItems: [Content.Item] { get }
    
    func publisher(triggerId: Trigger.Id, filter: SectionFiltering?) -> AnyPublisher<[Content.Item], Error>?
}

extension SectionProperties {
    func publisher(triggerId: Trigger.Id) -> AnyPublisher<[Content.Item], Error>? {
        return publisher(triggerId: triggerId, filter: nil)
    }
}
