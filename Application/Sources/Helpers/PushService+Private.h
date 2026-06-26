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

@end

@interface PushService (Helpers)

/**
 *  Return `YES` if show subscriptions can be changed. If notifications are not enabled the system permission prompt
 *  or an alert directing the user to Settings is presented, and the method returns `NO`.
 */
- (BOOL)requestSubscriptionAuthorization;

/**
 *  Toggle subscription for the specified show. Callers must ensure `-requestSubscriptionAuthorization` returns `YES` first.
 */
- (void)toggleSubscriptionForShow:(SRGShow *)show;

@end

NS_ASSUME_NONNULL_END
