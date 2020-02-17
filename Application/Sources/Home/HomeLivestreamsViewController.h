//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSectionInfo.h"
#import "MediasViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface HomeLivestreamsViewController : CollectionRequestViewController <SRGAnalyticsViewTracking>

- (instancetype)initWithHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo;

@property (nonatomic, readonly) HomeSectionInfo *homeSectionInfo;

@end

@interface HomeLivestreamsViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
