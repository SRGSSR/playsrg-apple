//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

// MARK: Controller

final class CarPlayNowPlayingController: CarPlayTemplateController {
    init() {}
    
    func willAppear(animated: Bool) {}
    
    func didAppear(animated: Bool) {
        SRGAnalyticsTracker.shared.uncheckedTrackPageView(
            withTitle: AnalyticsPageTitle.player.rawValue,
            levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.automobile.rawValue]
        )
    }
    
    func willDisappear(animated: Bool) {}
    
    func didDisappear(animated: Bool) {}
}
