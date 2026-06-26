//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if os(iOS)
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

        /// SDK-internal storage key (UserDefaults+PushSubscription.swift).
        private static let pushSDKTagsKey = "PushSDK.tags"

        /// SDK's getTags() is actor-isolated, so read the persisted [channel: tags] blob directly. Assert if it no
        /// longer decodes, which means the SDK changed its storage format.
        @objc static func getTags(forChannel channel: String) -> [String] {
            guard let data = UserDefaults.standard.data(forKey: pushSDKTagsKey) else {
                return []
            }
            guard let allTags = try? JSONDecoder().decode([String: [String]].self, from: data) else {
                assertionFailure("PushSDK changed its persisted tags format under \"\(pushSDKTagsKey)\"; PushSubscriptionBridge.getTags(forChannel:) must be updated.")
                return []
            }
            return allTags[channel] ?? []
        }
    }
#endif
