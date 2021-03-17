//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionRequestViewController.h"
#import "PlayApplicationNavigation.h"

@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface SearchViewController : CollectionRequestViewController <PlayApplicationNavigation, SRGAnalyticsViewTracking, UISearchBarDelegate, UISearchResultsUpdating>

@end

NS_ASSUME_NONNULL_END
