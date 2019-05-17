//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PushService.h"

NS_ASSUME_NONNULL_BEGIN

@interface PushService (Private)

/**
 *  Add subscription for the specified show.
 */
- (void)subscribeToShow:(SRGShow *)show;

/**
 *  Remove any subscription for the specified show.
 */
- (void)unsubscribeFromShow:(SRGShow *)show;

/**
 *  Remove any subscription for the specified show urns.
 *
 *  @discussion: No notification sent.
 */
- (void)silenceUnsubscribtionFromShowURNs:(NSSet<NSString *> *)showURNs;

/**
 *  Return YES iff the user has subscribed to the specified show.
 */
- (BOOL)isSubscribedToShow:(SRGShow *)show;

/**
 *  Return the URNs of all shows the user has subscribed to.
 */
@property (nonatomic, readonly) NSSet<NSString *> *subscribedShowURNs;

@end

@interface PushService (Helpers)

/**
 *  Toggle subscription for the specified show.
 *
 *  @discussion Return `YES` if toggled, `NO` if notifications disabled.
 */
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show;

/**
 *  Toggle subscription for the specified show and notifified with a banner.
 *
 *  @discussion Return `YES` if toggled, `NO` if notifications disabled and display a a message to enabble it.
 */
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inView:(nullable UIView *)view;
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inViewController:(nullable UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
