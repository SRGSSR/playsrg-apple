//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

#pragma makr My List entries

/**
 *  Return `YES` if the show is in My List.
 *
 *  @discussion Must be called from the main thread,
 */
OBJC_EXPORT BOOL MyListContainsShow(SRGShow * _Nonnull show);

/**
 *  Add a show to My List.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT void MyListAddShow(SRGShow * _Nonnull show);

/**
 *  Remove mshows from My List. If `nil`, all shows are removed.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT void MyListRemoveShows(NSArray<SRGShow *> * _Nullable shows);

/**
 *  Toggle a show to My List.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT BOOL MyListToggleShow(SRGShow * _Nonnull show);

/**
 *  Get all show URNs in My List.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT NSSet<NSString *> * MyListShowURNs();

#pragma mark Subscriptions

/**
 *  Toggle a subscription to My List.
 *
 *  @discussion Must be called from the main thread.
 */
OBJC_EXPORT BOOL MyListToggleSubscriptionShow(SRGShow * _Nonnull show, UIView * _Nullable view, BOOL withBanner);

/**
 *  Return YES iff the user has subscribed to the specified show.
 */
OBJC_EXPORT BOOL MyListIsSubscribedToShow(SRGShow * _Nonnull show);

/**
 *  Migrate favorites (legacy plist-based way of bookmarking shows) and subscriptions, if any to My List.
 */
OBJC_EXPORT void MyListMigrate(void);

NS_ASSUME_NONNULL_END
