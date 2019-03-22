//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannel.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard navigation controller with Play look-and-feel and behavior.
 */
@interface NavigationController : UINavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController radioChannel:(nullable RadioChannel *)radioChannel;

@end

@interface NavigationController (Unavailable)

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
