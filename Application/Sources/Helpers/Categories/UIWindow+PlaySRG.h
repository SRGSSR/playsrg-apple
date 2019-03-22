//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (PlaySRG)

/**
 *  Return the topmost view controller (either root view controller or presented modally)
 */
@property (nonatomic, readonly, nullable) __kindof UIViewController *play_topViewController;

/**
 *  Dismiss all presented view controllers.
 */
- (void)play_dismissAllViewControllersAnimated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
