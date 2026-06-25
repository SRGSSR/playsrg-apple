//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notitfication sent when a push notification has been received by the device.
 */
OBJC_EXPORT NSString * const PushServiceDidReceiveNotification;

/**
 *  Notitfication sent when the badge number has changed on the device.
 */
OBJC_EXPORT NSString * const PushServiceBadgeDidChangeNotification;

/**
 *  Notification sent when the status of the service changes (`enabled` property).
 */
OBJC_EXPORT NSString * const PushServiceStatusDidChangeNotification;

/**
 *  Key storing the status of the push service, as an `NSumber` containing a boolean.
 */
OBJC_EXPORT NSString * const PushServiceEnabledKey;

/**
 *  Service for push notifications.
 */
@interface PushService : NSObject

/**
 *  Perform push notification setup.
 *
 *  @discussion This method must be called from `-application:didFinishLaunchingWithOptions:`, otherwise the behavior
 *              is undefined. It must be provided with the received launch options.
 */
- (void)setupWithLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions;

/**
 *  Service singleton. `nil` if push notifications are not available for the application.
 */
@property (class, nonatomic, readonly, nullable) PushService *sharedService;

/**
 *  Return `YES` iff push notifications are enabled in the system settings.
 */
@property (nonatomic, readonly, getter=isEnabled) BOOL enabled;

/**
 *  Return the current device token.
 */
@property (nonatomic, readonly, copy, nullable) NSString *deviceToken;

/**
 *  Return the current Airship (channel) identifier.
 */
@property (nonatomic, readonly, copy, nullable) NSString *airshipIdentifier;

/**
 *  Register the device token. Call from `application:didRegisterForRemoteNotificationsWithDeviceToken:`.
 */
- (void)registerDeviceToken:(NSData *)deviceToken;

/**
 *  Forward a remote-notification registration failure. Call from `application:didFailToRegisterForRemoteNotificationsWithError:`.
 */
- (void)applicationDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 *  Process a received remote notification. Call from `application:didReceiveRemoteNotification:fetchCompletionHandler:`.
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

/**
 *  Handle a notification response. Call from `userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:`.
 */
- (void)handleNotificationResponse:(UNNotificationResponse *)notificationResponse withCompletionHandler:(void (^)(void))completionHandler;

/**
 *  Process a notification about to be presented in the foreground. Call from
 *  `userNotificationCenter:willPresentNotification:withCompletionHandler:`.
 */
- (void)willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler;

/**
 *  Apply the user analytics consent to the underlying backends.
 */
- (void)setAnalyticsConsentGranted:(BOOL)granted;

/**
 *  Attempt to present the system alert to enable push notifications. Returns `YES` iff presented.
 */
- (BOOL)presentSystemAlertForPushNotifications;

/**
 *  Reset the application badge on the Springboard.
 */
- (void)resetApplicationBadge;

/**
 *  Update the application badge on the Springboard.
 */
- (void)updateApplicationBadge;

/**
 *  Return the URNs of all shows the user has subscribed to.
 */
@property (nonatomic, readonly) NSSet<NSString *> *subscribedShowURNs;

@end

NS_ASSUME_NONNULL_END
