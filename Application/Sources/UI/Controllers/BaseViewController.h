//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsConstants.h"
#import "Previewing.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Abstract common base view controller class for view controllers in the Play application. Subclasses can implement methods
 *  from the Subclassing category to specify analytics information if needed.
 *
 *  This class atuomatically provides:
 *    - Automatic page view tracking (using the view controller title as page title by default. Override if a different page
 *      title is required). Subclasses can also disable automatic tracking by implementing `-srg_isTrackedAutomatically` to
 *      return `NO`
 *    - Peek-and-pop standard management
 */
@interface BaseViewController : HLSViewController <LegacyPreviewingSupport, SRGAnalyticsViewTracking, UIViewControllerPreviewingDelegate>

@end

/**
 *  Subclassing hooks
 */
@interface BaseViewController (Subclassing)

/**
 *  The page type to be used for measurements
 */
@property (nonatomic, readonly) AnalyticsPageType pageType;

@end

NS_ASSUME_NONNULL_END
