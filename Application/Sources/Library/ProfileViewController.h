//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"
#import "ContentInsets.h"
#import "PlayApplicationNavigation.h"
#import "TabBarActionable.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : BaseViewController <ContentInsets, PlayApplicationNavigation, SRGAnalyticsViewTracking, TabBarActionable, UITableViewDataSource, UITableViewDelegate>

@end

NS_ASSUME_NONNULL_END
