//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay
import SRGAnalytics

// MARK: Protocol

/**
 *  Have controllers associated with CarPlay templates conform to the following protocol so that they can be tracked.
 */
protocol CarPlayTracking {
    var pageViewTitle: String? { get }
    var pageViewLevels: [String]? { get }
}

// MARK: Analytics extensions

extension SRGAnalyticsTracker {
    /**
     *  Track a page view for the specified template. If the template has no associated tracking information this
     *  method does nothing.
     */
    func trackPageView(for template: CPTemplate) {
        if template is CPNowPlayingTemplate {
            trackPageView(
                withTitle: AnalyticsPageTitle.player.rawValue,
                levels: [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.carPlay.rawValue]
            )
        }
        else if let trackedController = template.controller as? CarPlayTracking, let title = trackedController.pageViewTitle {
            trackPageView(withTitle: title, levels: trackedController.pageViewLevels)
        }
    }
}
