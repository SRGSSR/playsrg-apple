//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if os(iOS)
    import Foundation
    import PushSDK
    import UIKit
    import UserNotifications

    /// `PushServiceBackend` implementation backed by the SRG PushSDK.
    ///
    /// All PushSDK knowledge is confined here. The backend is instantiated only when a push backend URL and channel are
    /// configured; it has no analytics nor app-delegate event forwarding, so the corresponding hooks are no-ops and
    /// `PushService` falls back to its own defaults.
    @objc final class PushSDKPushServiceBackend: NSObject, PushServiceBackend {
        /// SDK-internal storage key (`UserDefaults+PushSubscription.swift`), read directly because `getTags()` is
        /// actor-isolated.
        private static let tagsStorageKey = "PushSDK.tags"

        private let channel: String

        @objc static func make() -> PushSDKPushServiceBackend? {
            guard let host = Bundle.main.object(forInfoDictionaryKey: "PushSDKURL") as? String, !host.isEmpty,
                  let pushBackendURL = URL(string: "https://\(host)"),
                  let channel = Bundle.main.object(forInfoDictionaryKey: "PushSDKChannel") as? String, !channel.isEmpty
            else {
                return nil
            }
            return PushSDKPushServiceBackend(channel: channel, pushBackendURL: pushBackendURL)
        }

        private init(channel: String, pushBackendURL: URL) {
            self.channel = channel
            super.init()

            let pushConfiguration = Configuration(pushBackendHost: pushBackendURL)
            Task {
                await PushSubscriptionService.shared.configure(with: pushConfiguration)
            }
        }

        func setup(launchOptions _: [UIApplication.LaunchOptionsKey: Any]?) {}

        private(set) var deviceToken: String?

        var identifier: String? { nil }

        func register(deviceToken: Data) {
            self.deviceToken = deviceToken.map { String(format: "%02x", $0) }.joined()
            Task {
                await PushSubscriptionService.shared.setToken(deviceToken, for: channel, type: .push)
            }
        }

        var subscribedTags: [String] {
            guard let data = UserDefaults.standard.data(forKey: Self.tagsStorageKey) else {
                return []
            }
            guard let allTags = try? JSONDecoder().decode([String: [String]].self, from: data) else {
                assertionFailure("PushSDK changed its persisted tags format under \"\(Self.tagsStorageKey)\"; PushSDKPushServiceBackend.subscribedTags must be updated.")
                return []
            }
            return allTags[channel] ?? []
        }

        func setSubscribedTags(_ tags: [String]) {
            Task {
                await PushSubscriptionService.shared.setTags(tags, for: channel)
            }
        }

        func setBadgeNumber(_ badgeNumber: Int) {
            UIApplication.shared.applicationIconBadgeNumber = badgeNumber
        }

        func resetBadge() {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        func setAnalyticsConsent(granted _: Bool) {}

        func didFailToRegisterForRemoteNotifications(error _: Error) {}

        func handleRemoteNotification(_: [AnyHashable: Any], fetchCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
            false
        }

        func handleNotificationResponse(_: UNNotificationResponse, completionHandler _: @escaping () -> Void) -> Bool {
            false
        }

        func willPresentNotification(_: UNNotification, completionHandler _: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
            false
        }
    }
#endif
