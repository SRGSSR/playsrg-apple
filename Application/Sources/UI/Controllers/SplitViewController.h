//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Orientation.h"
#import "PlayApplicationNavigation.h"
#import "ScrollableContent.h"
#import "TabBarActionable.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Lightweight split view controller subclass with standard behavior.
 */
@interface SplitViewController : UISplitViewController <Oriented, PlayApplicationNavigation, ScrollableContentContainer, TabBarActionable, UISplitViewControllerDelegate>

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
