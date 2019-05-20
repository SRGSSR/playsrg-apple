//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Play domain for `SRGPreferences`.
 */
OBJC_EXPORT NSString * const PlayPreferenceDomain;

#pragma mark My List entries

/**
 *  Return `YES` if the show is in My List.
 */
OBJC_EXPORT BOOL MyListContainsShow(SRGShow * _Nonnull show);

/**
 *  Add a show to My List.
 */
OBJC_EXPORT void MyListAddShow(SRGShow * _Nonnull show);

/**
 *  Remove shows from My List. If `nil`, all shows are removed.
 */
OBJC_EXPORT void MyListRemoveShows(NSArray<SRGShow *> * _Nullable shows);

/**
 *  Toggle a show in My List.
 */
OBJC_EXPORT BOOL MyListToggleShow(SRGShow * _Nonnull show);

/**
 *  Get all show URNs in My List.
 */
OBJC_EXPORT NSSet<NSString *> * _Nonnull MyListShowURNs(void);


/**
 *  @name Subscriptions
 */

/**
 *  Toggle a subscription to My List.
 *
 *  @discussion The optional view gives the opportunity to display an alter if Push notifications are disabled.
 */
OBJC_EXPORT BOOL MyListToggleSubscriptionForShow(SRGShow * _Nonnull show, UIView * _Nullable view);

/**
 *  Return YES iff the user has subscribed to the specified show.
 */
OBJC_EXPORT BOOL MyListIsSubscribedToShow(SRGShow * _Nonnull show);


/**
 *  @name Setup
 */

/**
 * Setup My List, to synchronize subscribed shows at any time.
 *
 *  @discussion Needs to be call after the Push Service setup.
 */
OBJC_EXPORT void MyListSetup(void);
    

/**
 *  @name Migration
 */

/**
 *  Migrate favorites (legacy plist-based way of bookmarking shows) and subscriptions, if any to My List.
 */
OBJC_EXPORT void MyListMigrate(void);

NS_ASSUME_NONNULL_END
