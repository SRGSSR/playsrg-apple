//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Valid notification types
 */
typedef NS_ENUM(NSInteger, UserNotificationType) {
    /**
     *  Not specified.
     */
    UserNotificationTypeNone = 0,
    /**
     *  A new on-demand content is available.
     */
    UserNotificationTypeNewOnDemandContentAvailable
};

/**
 *  Conversion between notification types and underlying string representations.
 */
OBJC_EXPORT UserNotificationType UserNotificationTypeFromString(NSString *notificationType);
OBJC_EXPORT NSString * _Nullable UserNotificationTypeString(UserNotificationType notificationType);

/**
 *  Push notification information.
 */
@interface UserNotification : NSObject

/**
 *  List of currently available notifications.
 */
@property (class, nonatomic, readonly) NSArray<UserNotification *> *notifications;

/**
 *  List of currently unread notifications.
 */
@property (class, nonatomic, readonly) NSArray<UserNotification *> *unreadNotifications;

/**
 *  Save a new notification or update an existing one.
 *
 *  @discussion A read notification cannot be marked as unread again.
 */
+ (void)saveNotification:(UserNotification *)notification read:(BOOL)read;

/**
 *  Remove a notification.
 */
+ (void)removeNotification:(UserNotification *)notification;

/**
 *  Create a notification from a system notification request.
 */
- (instancetype)initWithRequest:(UNNotificationRequest *)notificationRequest;

/**
 *  Create a notification from a system notification.
 */
- (instancetype)initWithNotification:(UNNotification *)notification;

/**
 *  The notification identifier.
 */
@property (nonatomic, readonly, copy) NSString *identifier;

/**
 *  The notification title.
 */
@property (nonatomic, readonly, copy) NSString *title;

/**
 *  The notification subtitle.
 */
@property (nonatomic, readonly, copy) NSString *body;

/**
 *  The URL of the image associated with the notification, if any.
 */
@property (nonatomic, readonly, nullable) NSURL *imageURL;

/**
 *  The date at which the notification was sent.
 */
@property (nonatomic, readonly) NSDate *date;

/**
 *  `YES` iff the notification has been read.
 */
@property (nonatomic, readonly, getter=isRead) BOOL read;

/**
 *  The type of the notification.
 */
@property (nonatomic, readonly) UserNotificationType type;

/**
 *  The URN of the media associated with the notification, if any.
 */
@property (nonatomic, readonly, copy, nullable) NSString *mediaURN;

/**
 *  The URN of the show associated with the notification, if any.
 */
@property (nonatomic, readonly, copy, nullable) NSString *showURN;

/**
 *  The identifier of the channel associated with the notification, if any.
 */
@property (nonatomic, readonly, copy, nullable) NSString *channelUid;

@end

NS_ASSUME_NONNULL_END
