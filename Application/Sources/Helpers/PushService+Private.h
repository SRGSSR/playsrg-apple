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
 *  Reconcile the active push backends with the show subscriptions stored in SRG User Data.
 *
 *  @discussion The push service is level-triggered: it derives the full set of subscribed shows from SRG User Data,
 *              which callers must therefore update beforehand.
 */
- (void)synchronizeSubscriptions;

@end

@interface PushService (Helpers)

/**
 *  Return `YES` if show subscriptions can be changed. If notifications are not enabled the system permission prompt
 *  or an alert directing the user to Settings is presented, and the method returns `NO`.
 */
- (BOOL)requestSubscriptionAuthorization;

@end

NS_ASSUME_NONNULL_END
