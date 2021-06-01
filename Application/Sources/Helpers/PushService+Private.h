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
 *  Toggle subscription for the specified show and notifified with a banner. Return `YES` if toggled. If notifications
 *  are not enabled an alert is presented to ask the user to enable push notifications instead. The toggle action is
 *  ignored and the method returns `NO`.
 *
 *  @discussion Use versions with a view or view controller parameter to provide a presentation context when possible.
 *              Only use the version without context if no such context can be found.
 */
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show;
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inView:(nullable UIView *)view;
- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inViewController:(nullable UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
