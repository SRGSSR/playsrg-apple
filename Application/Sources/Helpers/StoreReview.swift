//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import StoreKit

@objc class StoreReview: NSObject {
    /**
     *  Gracefully request for an AppStore review.
     *
     *  @see `SKStoreReviewController` documentation for more information.
     */
    @objc static func requestReview() {
#if !DEBUG && !NIGHTLY && !BETA
        let userDefaultsKey = "PlaySRGStoreReviewRequestCount"
        let userDefaults = UserDefaults.standard
        var requestCount = userDefaults.integer(forKey: userDefaultsKey) + 1
        let requestCountThreshold = 50
        
        if requestCount >= requestCountThreshold {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
            requestCount = 0
        }
        
        userDefaults.set(requestCount, forKey: userDefaultsKey)
        userDefaults.synchronize()
#endif
    }
}
