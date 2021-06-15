//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Manage a custom modal transition.
 *
 *  @discussion Use `play_`-prefixed methods available from `UIViewController+PlaySRG.h` when presenting view
 *              controllers using custom modal transitions, otherwise the behavior is undefined.
 */
@interface ModalTransition : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

/**
 *  Create a modal transition. Set presentation to `YES` for the presentation version, `NO` for dismissal.
 */
- (instancetype)initForPresentation:(BOOL)presentation;

/**
 *  Update the interactive transition progress
 */
- (void)updateInteractiveTransitionWithProgress:(CGFloat)progress;

/**
 *  Finish the interactive transition
 */
- (void)finishInteractiveTransition;

/**
 *  Cancel the interactive transition
 */
- (void)cancelInteractiveTransition;

/**
 *  `YES` iff the transition was cancelled by the user.
 */
@property (nonatomic, readonly) BOOL wasCancelled;

@end

NS_ASSUME_NONNULL_END
