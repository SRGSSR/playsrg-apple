//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationService.h"

#import "Notification.h"

@interface NotificationService ()

@property (nonatomic, copy) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic) UNMutableNotificationContent *originalNotificationContent;

@end

@implementation NotificationService

#pragma mark Subclassing hooks

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
    self.contentHandler = contentHandler;
    self.originalNotificationContent = [request.content mutableCopy];
    
    Notification *notification = [[Notification alloc] initWithRequest:request];
    [Notification saveNotification:notification read:NO];
    
    self.contentHandler(self.originalNotificationContent);
}

- (void)serviceExtensionTimeWillExpire
{
    self.contentHandler(self.originalNotificationContent);
}

@end
