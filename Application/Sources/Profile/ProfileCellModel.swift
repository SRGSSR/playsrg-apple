//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProfileCellModel: ObservableObject {
    @Published var applicationSectioninfo: ApplicationSectionInfo?
    
    @Published private(set) var unreads = false
    
    init() {
        $applicationSectioninfo
            .dropFirst()
            .map { applicationSectioninfo in
                guard applicationSectioninfo?.applicationSection == .notifications else {
                    return Just(false).eraseToAnyPublisher()
                }
                return Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) {
                    return ApplicationSignal.hasUserUnreadNotifications()
                }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$unreads)
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
