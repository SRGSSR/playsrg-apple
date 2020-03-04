//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "PlayApplicationNavigation.h"
#import "RequestViewController.h"
#import "RadioChannel.h"
#import "Scrollable.h"

#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface HomeViewController : RequestViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, PlayApplicationNavigation, Scrollable, SRGAnalyticsViewTracking, UITableViewDataSource, UITableViewDelegate>

/**
 *  Instantiate a home displaying the provided sections, related to the specified radio channel (or TV in general if none
 *  is provided).
 */
- (instancetype)initWithHomeSections:(NSArray<NSNumber *> *)homeSections radioChannel:(nullable RadioChannel *)radioChannel NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, nullable) RadioChannel *radioChannel;

@end

@interface HomeViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

