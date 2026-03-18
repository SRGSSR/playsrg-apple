//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import AirshipCore
import UIKit
import UserNotifications

// UIApplicationDelegate push registration and remote notification methods.
// Required because Airship's automatic setup (swizzling) is disabled during parallel migration.
extension AppDelegate {
    @objc func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        AppIntegration.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        PushService.sharedService?.registerDeviceToken(deviceToken)
    }

    @objc func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppIntegration.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    @objc func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if userInfo.isAirshipPayload {
            Task {
                let result = await AppIntegration.application(application, didReceiveRemoteNotification: userInfo)
                completionHandler(result)
            }
        } else {
            completionHandler(.newData)
        }
    }
}

// UNUserNotificationCenterDelegate conformance.
// Forwards to Airship's AppIntegration, which then calls UAPushNotificationDelegate (PushService).
extension AppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: {})
        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task {
            let options = await AppIntegration.userNotificationCenter(center, willPresent: notification)
            completionHandler(options)
        }
    }
}

private extension Dictionary where Key == AnyHashable {
    // Detect Airship payloads by their characteristic keys.
    var isAirshipPayload: Bool {
        keys.contains { key in
            guard let key = key as? String else { return false }
            return key.hasPrefix("com.urbanairship") || key == "_"
        }
    }
}
