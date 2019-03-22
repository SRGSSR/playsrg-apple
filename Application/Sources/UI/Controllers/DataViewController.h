//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Abstract base view controller class for custom view controllers displaying data. Subclasses can implement methods
 *  from the Subclassing category to specify how refreshing is performed
 *
 *  In addition to behaviors inherited from `BaseViewController`, this class provides the following features:
 *   - Automatic data refresh when the view is displayed for the first time or when the application wakes from the
 *     background with the view visible
 *   - A message is displayed when no connection is available. A refresh is performed automatically when the
 *     connection is restored
 */
@interface DataViewController : BaseViewController

@end

/**
 *  Subclassing hooks
 */
@interface DataViewController (Subclassing)

/**
 *  This method is called when a refresh must be made. Subclassers can implement this method to perform a request
 *  or reload a collection directly, for example
 */
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
