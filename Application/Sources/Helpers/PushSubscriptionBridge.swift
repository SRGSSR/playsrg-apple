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
        NSLog("[PushSDK] Configuring push backend: URL=%@", pushBackendURL.absoluteString)
        let config = Configuration(pushBackendHost: pushBackendURL)
        Task {
            await PushSubscriptionService.shared.configure(with: config)
        }
    }

    @objc static func setToken(_ token: Data, forChannel channel: String) {
        NSLog("[PushSDK] Setting token: channel=%@, token=%@", channel, token as NSData)
        Task {
            await PushSubscriptionService.shared.setToken(token, for: channel, type: .push)
        }
    }

    @objc static func setTags(_ tags: [String], forChannel channel: String) {
        NSLog("[PushSDK] Setting tags: channel=%@, tags=%@", channel, tags)
        Task {
            await PushSubscriptionService.shared.setTags(tags, for: channel)
        }
    }

    /// PushSubscriptionService.getTags() is actor-isolated and cannot be called synchronously from ObjC.
    /// Reading from UserDefaults directly mirrors what the SDK does internally (UserDefaults+PushSubscription.swift, key "PushSDK.tags").
    @objc static func getTags(forChannel channel: String) -> [String] {
        guard let data = UserDefaults.standard.data(forKey: "PushSDK.tags"),
              let allTags = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            NSLog("[PushSDK] No tags found: channel=%@", channel)
            return []
        }
        let channelTags = allTags[channel] ?? []
        NSLog("[PushSDK] Getting tags: channel=%@, tags=%@", channel, channelTags)
        return channelTags
    }
}
