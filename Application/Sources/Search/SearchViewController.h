//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionRequestViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchViewController : CollectionRequestViewController <SRGAnalyticsViewTracking, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

/**
 *  Create a search view controller with optional query and settings.
 *
 *  @param query     The query.
 *  @param settings  The search settings. Only used if search settings is enabled (@see `searchSettingsDisabled` in `ApplicationConfiguration`).
 */
- (instancetype)initWithQuery:(nullable NSString *)query settings:(nullable SRGMediaSearchSettings *)settings;

/**
 *  If set, a close button will be displayed, executing the block when tapped. The block must be set before the view
 *  controller is displayed.
 */
@property (nonatomic, copy, nullable) void (^closeBlock)(void);

@end

@interface SearchViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
