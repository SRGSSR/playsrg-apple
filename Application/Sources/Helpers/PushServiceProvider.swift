//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if os(iOS)
    import UIKit
    import UserNotifications

    /// A push notification delivery provider (e.g. Airship or the SRG PushSDK).
    ///
    /// `PushService` owns the application-level logic (user authorization, SRG User Data synchronization, tag <-> URN
    /// mapping, notification-response handling) and drives one or more providers through this abstraction, without any
    /// knowledge of the underlying SDK. During the Airship -> PushSDK migration both providers run side by side; dropping
    /// Airship later is a matter of no longer instantiating the associated provider.
    @objc protocol PushServiceProvider: AnyObject {
        /// Perform the provider-specific setup. Called once from `-application:didFinishLaunchingWithOptions:`.
        @objc(setupWithLaunchOptions:)
        func setup(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)

        /// The current device token, or `nil` if not available.
        var deviceToken: String? { get }

        /// A provider-specific identifier (e.g. the Airship channel identifier), or `nil` if the provider has none.
        var identifier: String? { get }

        /// Register the device token with the provider. Called from `-application:didRegisterForRemoteNotificationsWithDeviceToken:`.
        @objc(registerDeviceToken:)
        func register(deviceToken: Data)

        /// The tags the device is currently subscribed to.
        var subscribedTags: [String] { get }

        /// Reconcile the provider subscription so that exactly `tags` are subscribed.
        func setSubscribedTags(_ tags: [String])

        /// Update the application badge number.
        func setBadgeNumber(_ badgeNumber: Int)

        /// Reset the application badge.
        func resetBadge()

        /// Apply the user analytics consent to the provider (no-op for providers without analytics).
        @objc(setAnalyticsConsentGranted:)
        func setAnalyticsConsent(granted: Bool)

        /// Forward a remote-notification registration failure. Called from `-application:didFailToRegisterForRemoteNotificationsWithError:`.
        func didFailToRegisterForRemoteNotifications(error: Error)

        /// Process a received remote notification. Return `true` iff the provider took ownership of `fetchCompletionHandler`.
        func handleRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool

        /// Process a notification response. Return `true` iff the provider took ownership of `completionHandler`.
        func handleNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) -> Bool

        /// Process a notification about to be presented in the foreground. Return `true` iff the provider took ownership of `completionHandler`.
        func willPresentNotification(_ notification: UNNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool
    }
#endif
