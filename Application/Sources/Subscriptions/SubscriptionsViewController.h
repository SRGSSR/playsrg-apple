//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "RequestViewController.h"

#import <DZNEmptyDataSet/DZNEmptyDataSet.h>

NS_ASSUME_NONNULL_BEGIN

// We don't use `TableRequestViewController` as parent class, as we prefer sorting items alphabetically once we have
// them all, which prevents the use of pages).
@interface SubscriptionsViewController : RequestViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UITableViewDataSource, UITableViewDelegate>

@end

NS_ASSUME_NONNULL_END
