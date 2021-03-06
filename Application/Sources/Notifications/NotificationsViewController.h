//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "DataViewController.h"
#import "Notification.h"

@import DZNEmptyDataSet;
@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface NotificationsViewController : DataViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SRGAnalyticsViewTracking, UITableViewDataSource, UITableViewDelegate>

+ (void)openNotification:(Notification *)notification fromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
