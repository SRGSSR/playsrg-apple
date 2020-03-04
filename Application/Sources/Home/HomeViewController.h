//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSectionInfo.h"
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
 *  Instantiate a home for the specified application section, displayed the provided home sections.
 */
- (instancetype)initWithApplicationSectionInfo:(ApplicationSectionInfo *)applicationSection homeSections:(NSArray<NSNumber *> *)homeSections NS_DESIGNATED_INITIALIZER;

/**
 *  The associated radio channel, if any.
 */
@property (nonatomic, readonly, nullable) RadioChannel *radioChannel;

@end

@interface HomeViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

