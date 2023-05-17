//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProfileCellModel: ObservableObject {
    @Published var applicationSectioninfo: ApplicationSectionInfo?
    
    init() {
    }
}

// MARK: Properties

extension ProfileCellModel {
    var image: UIImage? {
        return applicationSectioninfo?.image
    }
    
    var title: String? {
        return applicationSectioninfo?.title
    }
    
    var isModalPresentation: Bool {
        return applicationSectioninfo?.isModalPresentation ?? false
    }
}
