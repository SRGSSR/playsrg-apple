//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol to be used by source views to setup associated peek-and-pop behavior
 */
@protocol Previewing <NSObject>

/**
 *  The preview object attached to the source view
 */
@property (nonatomic, readonly) id previewObject;

@optional

/**
 *  The rect where the long-press popover will be anchored in the source view. If `nil` or not implemented, the entire
 *  source view rect is used.
 */
@property (nonatomic, readonly, nullable) NSValue *previewAnchorRect;

@end

@protocol PreviewingDelegate <UIViewControllerPreviewingDelegate>

/**
 *  Method which gets called when a long press is detected. This can be implemented as an alternative to 3D Touch,
 *  most notably on devices without 3D Touch support or if 3D Touch has been disabled in the Accessibility settings.
 */
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;

/**
 *  The view controller to use for preview registration.
 */
@property (nonatomic, readonly) UIViewController *previewContextViewController;

@end

@interface UIView (Previewing)

/**
 *  Update registrations in the view hierarchy rooted at the specified view.
 */
+ (void)play_updatePreviewRegistrationsInView:(UIView *)view;

/**
 *  Register the receiver for previewing. Requires a parent view controller to conform to the `PreviewingDelegate`
 *  protocol.
 */
- (void)play_registerForPreview;

@end

NS_ASSUME_NONNULL_END
