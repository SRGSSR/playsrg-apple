//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Conform any view controller to `Oriented` to have it support intended orientations for the application. You can
 *  still customize rotation behavior should the default behavior require adjustments on a view controller basis.
 *
 *  Remark: View controllers conforming to this protocol should not implement `supportedInterfaceOrientation` explicitly,
 *          otherwise the behavior is undefined.
 */
@protocol Oriented <NSObject>

@optional

/**
 *  The interface orientations supported by the receiver (ignoring other view controllers). If not implemented assumes
 *  that standard orientations are supported (i.e. portrait on iPhone, all on iPad).
 */
@property (nonatomic, readonly) UIInterfaceOrientationMask play_supportedInterfaceOrientations;

/**
 *  Return `YES` iff the view controller covers the whole screen when displayed modally. Only relevant when the
 *  view controller is presented with `UIModalPresentationCustom`. Same as `NO` if not implemented.
 */
@property (nonatomic, readonly) BOOL play_isFullScreenWhenDisplayedInCustomModal;

/**
 *  The list of children participating in the orientation resolution, if any.
 */
@property (nonatomic, readonly) NSArray<UIViewController *> *play_orientingChildViewControllers;

@end

@interface UIViewController (Orientation)

/**
 *  Present the view controller, ensuring that view lifecycle events are properly forwarded if a custom transition is applied.
 *
 *  @discussion Useful when a custom modal presentation style is applied. In general you can use standard dismissal.
 */
- (void)play_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/**
 *  Dismiss the view controller, ensuring a compatible suitable orientation is applied to the revealed view controller,
 *  and that view lifecycle events are properly forwarded if a custom transition is applied.
 *
 *  @discussion Useful when a custom modal presentation style is applied. In general you can use standard dismissal.
 */
- (void)play_dismissViewControllerAnimated:(BOOL)animated completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
