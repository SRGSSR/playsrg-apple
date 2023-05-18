//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProfileCellModel: ObservableObject {
    @Published var applicationSectioninfo: ApplicationSectionInfo?
    
    @Published private(set) var unreadNotifications = false
    
    init() {
        $applicationSectioninfo
            .dropFirst()
            .filter { $0?.applicationSection == .notifications }
            .map { _ in
                return ApplicationSignal.pushServiceHasBadgeUpdate()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$unreadNotifications)
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
