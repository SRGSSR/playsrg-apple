//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayApplicationNavigation.h"
#import "TabBarActionable.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Lightweight split view controller subclass with standard behavior.
 */
@interface SplitViewController : UISplitViewController <PlayApplicationNavigation, TabBarActionable>

@end

NS_ASSUME_NONNULL_END
