//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension SRGAnalyticsTracker {
    func trackPageView(title: String, levels: [String]) {
        self.trackPageView(withTitle: title, levels: levels)
    }
}
