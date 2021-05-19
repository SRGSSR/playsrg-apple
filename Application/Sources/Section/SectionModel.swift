//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

class SectionModel: ObservableObject {
    let section: Content.Section
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Content.Section) {
        self.section = section
    }
}
