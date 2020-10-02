//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "DataViewController.h"
#import "NotificationTableViewCell.h"

#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface NotificationsViewController : DataViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, NotificationTableViewDeletionDelegate, SRGAnalyticsViewTracking, UITableViewDataSource, UITableViewDelegate>

+ (void)openNotification:(Notification *)notification fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
