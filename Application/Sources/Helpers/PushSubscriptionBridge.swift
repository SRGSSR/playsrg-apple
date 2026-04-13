//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import PushSDK

/// ObjC-callable bridge to PushSDK's PushSubscriptionService.
@objc final class PushSubscriptionBridge: NSObject {
    @objc(configurePushBackendURL:) static func configure(pushBackendURL: URL) {
        let config = Configuration(pushBackendHost: pushBackendURL)
        Task {
            await PushSubscriptionService.shared.configure(with: config)
        }
    }

    @objc static func setToken(_ token: Data, forChannel channel: String) {
        Task {
            await PushSubscriptionService.shared.setToken(token, for: channel, type: .push)
        }
    }

    @objc static func setTags(_ tags: [String], forChannel channel: String) {
        Task {
            await PushSubscriptionService.shared.setTags(tags, for: channel)
        }
    }
}
