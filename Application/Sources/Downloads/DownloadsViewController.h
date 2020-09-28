//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "DataViewController.h"

#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface DownloadsViewController : DataViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SRGAnalyticsViewTracking, UITableViewDataSource, UITableViewDelegate>

@end

NS_ASSUME_NONNULL_END
