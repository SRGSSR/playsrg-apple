//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if os(iOS)
    import AirshipCore
    import UIKit
    import UserNotifications

    /// `PushServiceProvider` implementation backed by Airship.
    ///
    /// All Airship knowledge is confined here: `PushService` never references `Airship` or `UAAppIntegration`. The
    /// provider takes off only when a valid `AirshipConfig.plist` is bundled; otherwise it is not instantiated and the
    /// service runs on the PushSDK provider alone.
    @objc final class AirshipPushServiceProvider: NSObject, PushServiceProvider {
        /// Marker tag letting the provider exclude migrated devices from Airship audiences.
        private static let migrationMarkerTag = "uses_push_sdk"

        private let configuration: Config

        /// Returns `nil` when no valid Airship configuration is bundled, in which case Airship must stay grounded and
        /// the service runs on the PushSDK provider alone.
        @objc static func make() -> AirshipPushServiceProvider? {
            guard let path = Bundle.main.path(forResource: "AirshipConfig", ofType: "plist") else {
                return nil
            }
            let configuration = Config(contentsOfFile: path)
            guard configuration.validate() else {
                return nil
            }
            return AirshipPushServiceProvider(configuration: configuration)
        }

        private init(configuration: Config) {
            self.configuration = configuration
            super.init()
        }

        func setup(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
            // Disable automatic swizzling so push events can be forwarded manually, allowing both providers to coexist.
            configuration.isAutomaticSetupEnabled = false

            Airship.takeOff(configuration, launchOptions: launchOptions)
            Airship.shared.privacyManager.disableFeatures(.analytics)

            Airship.push.defaultPresentationOptions = [.list, .banner, .badge, .sound]
            Airship.push.autobadgeEnabled = true
        }

        var deviceToken: String? {
            Airship.isFlying ? Airship.push.deviceToken : nil
        }

        var identifier: String? {
            Airship.isFlying ? Airship.channel.identifier : nil
        }

        func register(deviceToken: Data) {
            guard Airship.isFlying else { return }
            AppIntegration.application(.shared, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            Airship.push.userPushNotificationsEnabled = true
        }

        var subscribedTags: [String] {
            Airship.isFlying ? Airship.channel.tags : []
        }

        func setSubscribedTags(_ tags: [String]) {
            guard Airship.isFlying else { return }
            Airship.channel.editTags { editor in
                editor.set(tags + [Self.migrationMarkerTag])
            }
            Airship.push.updateRegistration()
        }

        func setBadgeNumber(_ badgeNumber: Int) {
            guard Airship.isFlying else { return }
            Airship.push.badgeNumber = badgeNumber
        }

        func resetBadge() {
            guard Airship.isFlying else { return }
            Airship.push.resetBadge()
        }

        func setAnalyticsConsent(granted: Bool) {
            guard Airship.isFlying else { return }
            if granted {
                Airship.shared.privacyManager.enableFeatures(.analytics)
            } else {
                Airship.shared.privacyManager.disableFeatures(.analytics)
            }
        }

        func didFailToRegisterForRemoteNotifications(error: Error) {
            guard Airship.isFlying else { return }
            AppIntegration.application(.shared, didFailToRegisterForRemoteNotificationsWithError: error)
        }

        func handleRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
            guard Airship.isFlying, Self.isAirshipPayload(userInfo) else { return false }
            AppIntegration.application(.shared, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: fetchCompletionHandler)
            return true
        }

        func handleNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) -> Bool {
            guard Airship.isFlying else { return false }
            AppIntegration.userNotificationCenter(.current(), didReceive: response, withCompletionHandler: completionHandler)
            return true
        }

        func willPresentNotification(_ notification: UNNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
            guard Airship.isFlying else { return false }
            AppIntegration.userNotificationCenter(.current(), willPresent: notification, withCompletionHandler: completionHandler)
            return true
        }

        /// A push payload is an Airship one when it carries a normal (`com.urbanairship`) or silent (`_`) Airship key.
        private static func isAirshipPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
            userInfo.keys.contains { key in
                guard let key = key as? String else { return false }
                return key.hasPrefix("com.urbanairship") || key == "_"
            }
        }
    }
#endif
