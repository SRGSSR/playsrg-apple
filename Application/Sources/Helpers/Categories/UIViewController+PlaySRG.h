//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProvider;
@import SRGLetterbox;
@import UIKit;

/**
 *  Player types.
 */
typedef NS_ENUM(NSInteger, PlayerType) {
    PlayerTypeNative,           // Native Letterbox-based player
    PlayerTypeGoogleCast        // Google Cast player interface
} API_UNAVAILABLE(tvos);

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (PlaySRG)

/**
 *  Return the standard user interface orientations supported by the application. Useful when implementing the
 *  `-supportedInterfaceOrientations` of a view controller
 */
@property (class, nonatomic, readonly) UIInterfaceOrientationMask play_supportedInterfaceOrientations API_UNAVAILABLE(tvos);

/**
 *  Convenience method to determine whether a view controller is appearing or disappearing. Take the parent view
 *  controller hierarchy in the process.
 *
 *  @discussion Must be called from -viewWill(Dis)Appear / -viewDid(Dis)Appear methods, otherwise the result is
 *              undefined
 */
- (BOOL)play_isMovingToParentViewController;
- (BOOL)play_isMovingFromParentViewController;

/**
 * Return YES iff the view is displayed and visible (appearing, appeared, or disappearing)
 */
@property (nonatomic, readonly, getter=play_isViewVisible) BOOL play_viewVisible;

/**
 *  The top view controller of the receiver hierarchy.
 */
@property (nonatomic, readonly) UIViewController *play_topViewController;

/**
 *  Play the specified media, presenting the appropriate media player based on the current context (whether Google Cast
 *  is enabled or not). The player is displayed modally, with the provided completion block called on completion. The
 *  player attempts to start at the specified position (use `nil` for the default location, resuming at the last playback
 *  location if available).
 *
 *  If the view controller implements the `PlaylistDataSource` protocol, an associated playlist will be attached
 *  accordingly.
 *
 *  On iOS 13 and above, AirPlay suggestions can be enabled so that the system, based on the user behavior, might offer
 *  a casting suggestion (https://developer.apple.com/videos/play/wwdc2019/501). On iOS 12 and below, this parameter is
 *  ignored.
 *
 *  The completion block is called when the media player has been presented (it will be called immediately if the
 *  player is readily visible). The type of player actually presented is returned.
 */
- (void)play_presentMediaPlayerWithMedia:(SRGMedia *)media
                                position:(nullable SRGPosition *)position
                      airPlaySuggestions:(BOOL)airPlaySuggestions
                    fromPushNotification:(BOOL)fromPushNotification
                                animated:(BOOL)animated
                              completion:(nullable void (^)(PlayerType playerType))completion API_UNAVAILABLE(tvos);

/**
 *  Same as `-play_presentMediaPlayerWithMedia:atPosition:fromPushNotification:animated:completion:`, but resuming from
 *  a Letterbox controller. Google Cast playback starts at the same position the controller was at.
 */
- (void)play_presentMediaPlayerFromLetterboxController:(SRGLetterboxController *)letterboxController
                                withAirPlaySuggestions:(BOOL)airPlaySuggestions
                                  fromPushNotification:(BOOL)fromPushNotification
                                              animated:(BOOL)animated
                                            completion:(nullable void (^)(PlayerType playerType))completion API_UNAVAILABLE(tvos);

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
