//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationConfiguration.h"
#import "PageViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT const NSInteger SearchViewControllerSearchTextMinimumLength;

@interface SearchViewController : PageViewController <UISearchBarDelegate, SRGAnalyticsViewTracking>

/**
 *  Instantiate the search, starting with the provided search option if available. If not, use the closest match.
 */
- (instancetype)initWithPreferredSearchOption:(SearchOption)searchOption;

/**
 *  Instantiate the search, starting with the first search option available.
 */
- (instancetype)init;

/**
 *  If set, a close button will be displayed, executing the block when tapped. The block must be set before the view
 *  controller is displayed.
 */
@property (nonatomic, copy, nullable) void (^closeBlock)(void);

@end

NS_ASSUME_NONNULL_END
