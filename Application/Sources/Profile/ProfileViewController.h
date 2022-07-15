//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"
#import "ContentInsets.h"
#import "Orientation.h"
#import "PlayApplicationNavigation.h"
#import "ScrollableContent.h"
#import "TabBarActionable.h"

@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : BaseViewController <ContentInsets, Oriented, PlayApplicationNavigation, ScrollableContent, SRGAnalyticsViewTracking, TabBarActionable, UITableViewDataSource, UITableViewDelegate>

@end

NS_ASSUME_NONNULL_END
