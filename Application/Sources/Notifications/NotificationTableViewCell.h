//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Notification.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NotificationTableViewCell;

@protocol NotificationTableViewCellDelegate <NSObject>

- (void)notificationTableViewCell:(NotificationTableViewCell *)cell willDeleteNotification:(Notification *)notification;

@end

@interface NotificationTableViewCell : MGSwipeTableCell

@property (nonatomic, nullable) Notification *notification;

@property (nonatomic, weak, nullable) id<NotificationTableViewCellDelegate> cellDelegate;

@end

NS_ASSUME_NONNULL_END
