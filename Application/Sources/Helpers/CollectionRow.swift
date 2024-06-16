//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

/**
 *  Collection row (might be empty).
 */
struct CollectionRow<Section: Hashable, Item: Hashable>: Hashable {
    /// Section.
    let section: Section
    /// Items contained within the section.
    let items: [Item]

    var isEmpty: Bool {
        return items.isEmpty
    }
}

/**
 *  Collection row (never empty).
 */
struct NonEmptyCollectionRow<Section: Hashable, Item: Hashable>: Hashable {
    /// Section.
    let section: Section
    /// Items contained within the section.
    let items: [Item]

    init?(section: Section, items: [Item]) {
        guard !items.isEmpty else { return nil }
        self.section = section
        self.items = items
    }
}
