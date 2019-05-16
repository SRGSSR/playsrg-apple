//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PushService.h"

NS_ASSUME_NONNULL_BEGIN

@interface PushService (Private)

/**
 *  Toggle subscription for the specified show.
 */
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show;

/**
 *  Add subscription for the specified show.
 */
- (BOOL)subscribeToShow:(SRGShow *)show;

/**
 *  Remove any subscription for the specified show.
 */
- (BOOL)unsubscribeFromShow:(SRGShow *)show;

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

- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inView:(nullable UIView *)view;
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inViewController:(nullable UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
