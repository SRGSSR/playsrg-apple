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
 *  Reconcile the active push providers with the show subscriptions stored in SRG User Data.
 *
 *  @discussion Derives the full subscription set from SRG User Data, which callers must update first.
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
