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
#import "TabBarActionable.h"

@import DZNEmptyDataSet;
@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface HomeViewController : RequestViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, PlayApplicationNavigation, SRGAnalyticsViewTracking, TabBarActionable, UITableViewDataSource, UITableViewDelegate>

/**
 *  Instantiate a home for the specified application section, displayed the provided home sections.
 */
- (instancetype)initWithApplicationSectionInfo:(ApplicationSectionInfo *)applicationSection homeSections:(NSArray<NSNumber *> *)homeSections;

/**
 *  The associated radio channel, if any.
 */
@property (nonatomic, readonly, nullable) RadioChannel *radioChannel;

@end

@interface HomeViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

