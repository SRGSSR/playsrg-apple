//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

class SectionModel: ObservableObject {
    let section: Section
    
    var title: String? {
        return section.properties.title
    }
    
    init(section: Section) {
        self.section = section
    }
}
