//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGDataProviderModel

struct Highlight: Hashable {
    let title: String
    let summary: String?
    let image: SRGImage?
    let imageFocalPoint: SRGFocalPoint?

    init?(from contentSection: SRGContentSection) {
        let presentation = contentSection.presentation
        guard let title = presentation.title else { return nil }
        self.init(title: title, summary: presentation.summary, image: presentation.image, imageFocalPoint: presentation.imageFocalPoint)
    }

    init(title: String, summary: String?, image: SRGImage?, imageFocalPoint: SRGFocalPoint?) {
        self.title = title
        self.summary = summary
        self.image = image
        self.imageFocalPoint = imageFocalPoint
    }
}
