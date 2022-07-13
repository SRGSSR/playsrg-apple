//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Conform any view controller to `Oriented` to have it support default orientations for the Play application. You
 *  can still customize rotation behavior by implementing its optional methods, should the default behavior require
 *  adjustments on a view controller basis.
 *
 *  Remark: View controllers conforming to this protocol should not implement `supportedInterfaceOrientation` explicitly,
 *          otherwise the behavior is undefined.
 */
API_UNAVAILABLE(tvos)
@protocol Oriented <NSObject>

@optional

/**
 *  The interface orientations intrinsically supported by the receiver, without taking account child, parent or
 *  presenting view controllers. If not implemented standard Play application orientations are assumed (i.e.
 *  portrait on iPhone, all on iPad).
 */
@property (nonatomic, readonly) UIInterfaceOrientationMask play_supportedInterfaceOrientations;

/**
 *  Return `YES` iff the view controller covers the whole screen when displayed modally. Only relevant when the
 *  view controller is presented with `UIModalPresentationCustom`. Assumed to be `NO` when not implemented.
 */
@property (nonatomic, readonly) BOOL play_isFullScreenWhenDisplayedInCustomModal;

/**
 *  The list of children participating in the overall receiver orientation, if any.
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
