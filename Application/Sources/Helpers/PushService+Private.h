//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PushService.h"

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface PushService (Private)

/**
 *  Add subscription for the specified show URNs.
 */
- (void)subscribeToShowURNs:(NSSet<NSString *> *)URNs;

/**
 *  Remove any subscription for the specified show URNs.
 *
 *  @discussion: No notification sent.
 */
- (void)unsubscribeFromShowURNs:(NSSet<NSString *> *)URNs;

/**
 *  Return YES iff the user has subscribed to the specified show URN.
 */
- (BOOL)isSubscribedToShowURN:(NSString *)URN;

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
