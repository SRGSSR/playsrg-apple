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
 *  Toggle subscription for the specified show and notifified with a banner. Return `YES` if toggled. If notifications
 *  are not enabled an alert is presented to ask the user to enable push notifications instead. The toggle action is
 *  ignored and the method returns `NO`.
 */
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show;

@end

NS_ASSUME_NONNULL_END
