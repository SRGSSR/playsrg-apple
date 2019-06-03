//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionRequestViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT const NSInteger SearchViewControllerSearchTextMinimumLength;

@interface SearchViewController : CollectionRequestViewController <UISearchBarDelegate, SRGAnalyticsViewTracking>

/**
 *  If set, a close button will be displayed, executing the block when tapped. The block must be set before the view
 *  controller is displayed.
 */
@property (nonatomic, copy, nullable) void (^closeBlock)(void);

@end

NS_ASSUME_NONNULL_END
